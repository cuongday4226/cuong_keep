import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:async';
import 'dart:io';
import '../models/database.dart';
import '../services/notification_service.dart';
import '../utils/string_utils.dart';

enum NoteFilter { notes, reminders, archive, trash, label }

class NotesViewModel extends ChangeNotifier {
  final AppDatabase _db;
  List<Note> _allNotes = []; // Tất cả ghi chú tải từ DB
  String _searchQuery = '';
  Timer? _reminderTimer;
  
  NoteFilter _currentFilter = NoteFilter.notes;
  String? _currentLabel;

  NoteFilter get currentFilter => _currentFilter;
  String? get currentLabel => _currentLabel;

  void setFilter(NoteFilter filter, {String? label}) {
    _currentFilter = filter;
    _currentLabel = label;
    notifyListeners();
  }

  // Lấy ra danh sách ghi chú tương ứng với Bộ lọc hiện tại (Filter)
  List<Note> get _filteredNotes {
    var list = _allNotes;
    
    // Áp dụng bộ lọc Navigation
    switch (_currentFilter) {
      case NoteFilter.notes:
        list = list.where((n) => !n.isDeleted && !n.isArchived).toList();
        break;
      case NoteFilter.reminders:
        list = list.where((n) => !n.isDeleted && n.reminderAt != null).toList();
        break;
      case NoteFilter.archive:
        list = list.where((n) => !n.isDeleted && n.isArchived).toList();
        break;
      case NoteFilter.trash:
        list = list.where((n) => n.isDeleted).toList();
        break;
      case NoteFilter.label:
        if (_currentLabel != null) {
          list = list.where((n) => !n.isDeleted && (n.tags?.contains(_currentLabel!) ?? false)).toList();
        }
        break;
    }
    return list;
  }

  List<Note> get notes => _filteredNotes;
  List<Note> get pinnedNotes => _filteredNotes.where((n) => n.isPinned).toList();
  List<Note> get unpinnedNotes => _filteredNotes.where((n) => !n.isPinned).toList();

  // Danh sách TẤT CẢ các nhãn có trong hệ thống
  List<String> get allTags {
    Set<String> tags = {};
    for (var note in _allNotes) {
      if (note.tags != null) {
        tags.addAll(note.tags!);
      }
    }
    return tags.toList()..sort();
  }

  String get searchQuery => _searchQuery;

  // --- TRẠNG THÁI ĐA CHỌN ---
  final Set<int> _selectedNoteIds = {};
  Set<int> get selectedNoteIds => _selectedNoteIds;
  bool get isSelectionMode => _selectedNoteIds.isNotEmpty;

  NotesViewModel(this._db) {
    _loadNotes();
    _startReminderTimer();
  }

  void _startReminderTimer() {
    // Cứ mỗi 30 giây kiểm tra 1 lần xem có báo thức nào tới hạn chưa
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final now = DateTime.now();
      // Copy list để tránh lỗi ConcurrentModificationError nếu setReminder làm thay đổi list
      final notesToCheck = _allNotes.toList(); 
      for (var note in notesToCheck) {
        if (note.reminderAt != null) {
          // Báo thức được tính là tới hạn nếu giờ hiện tại lớn hơn hoặc bằng giờ báo thức
          final diff = now.difference(note.reminderAt!);
          // Quá hạn hoặc tới hạn thì bắn thông báo (không giới hạn thời gian để bắt được những báo thức bị nhỡ khi tắt app)
          if (diff.inSeconds >= 0) {
            await NotificationService().showNotification(
              id: note.id,
              title: 'Nhắc nhở: ${note.title.isNotEmpty ? note.title : "Ghi chú"}',
              body: note.content,
            );
            // Sau khi thông báo, xóa hẹn giờ đi để không lặp lại
            await setReminder(note.id, null);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _db.close();
    super.dispose();
  }

  // Đóng database để phục vụ cho việc sao lưu / phục hồi
  Future<void> closeDatabase() async {
    await _db.close();
  }

  // --- HÀM TÌM KIẾM ---
  void setSearchQuery(String query) {
    _searchQuery = query;
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final query = _db.select(_db.notes)
          ..orderBy([
            (t) => drift.OrderingTerm(expression: t.isPinned, mode: drift.OrderingMode.desc),
            (t) => drift.OrderingTerm(expression: t.orderIndex, mode: drift.OrderingMode.asc)
          ]);

    var allNotes = await query.get();

    // Lọc theo từ khóa bằng Dart (Thông minh hơn)
    if (_searchQuery.isNotEmpty) {
      final normalizedQuery = StringUtils.removeDiacritics(_searchQuery.toLowerCase()).trim();
      final searchTerms = normalizedQuery.split(RegExp(r'\s+'));

      allNotes = allNotes.where((note) {
        final buffer = StringBuffer();
        buffer.writeln(note.title);
        buffer.writeln(note.content);
        
        if (note.isChecklist && note.checklistItems != null) {
          for (var item in note.checklistItems!) {
            buffer.writeln(item.text);
          }
        }
        
        final normalizedText = StringUtils.removeDiacritics(buffer.toString().toLowerCase());
        return searchTerms.every((term) => normalizedText.contains(term));
      }).toList();
    }

    _allNotes = allNotes;
    
    // Xóa những ID đã bị lọc khỏi danh sách được chọn
    final currentNoteIds = _filteredNotes.map((n) => n.id).toSet();
    _selectedNoteIds.removeWhere((id) => !currentNoteIds.contains(id));

    notifyListeners();
  }

  // --- HÀM XỬ LÝ ĐA CHỌN ---
  void toggleSelection(int id) {
    if (_selectedNoteIds.contains(id)) {
      _selectedNoteIds.remove(id);
    } else {
      _selectedNoteIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedNoteIds.isNotEmpty) {
      _selectedNoteIds.clear();
      notifyListeners();
    }
  }

  void selectAll() {
    for (var note in _allNotes) {
      _selectedNoteIds.add(note.id);
    }
    notifyListeners();
  }

  Future<void> moveSelectedNotesToTrash() async {
    if (_selectedNoteIds.isEmpty) return;
    for (int id in _selectedNoteIds) {
      await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
        const NotesCompanion(isDeleted: drift.Value(true))
      );
    }
    _selectedNoteIds.clear();
    await _loadNotes();
  }

  Future<void> restoreSelectedNotes() async {
    if (_selectedNoteIds.isEmpty) return;
    for (int id in _selectedNoteIds) {
      await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
        const NotesCompanion(isDeleted: drift.Value(false))
      );
    }
    _selectedNoteIds.clear();
    await _loadNotes();
  }

  Future<void> permanentlyDeleteSelectedNotes() async {
    if (_selectedNoteIds.isEmpty) return;
    for (int id in _selectedNoteIds) {
      _deleteNoteFiles(id);
      await (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();
    }
    _selectedNoteIds.clear();
    await _loadNotes();
  }
  
  // Xóa rác: Dùng chung 1 hàm hỗ trợ xóa file ảnh đính kèm
  void _deleteNoteFiles(int id) {
    try {
      final note = _allNotes.firstWhere((n) => n.id == id);
      if (note.imagePaths != null && note.imagePaths!.isNotEmpty) {
        for (var path in note.imagePaths!) {
          final file = File(path);
          if (file.existsSync()) file.deleteSync();
        }
      }
    } catch (e) {
      // Bỏ qua lỗi
    }
  }

  Future<void> togglePinSelectedNotes() async {
    if (_selectedNoteIds.isEmpty) return;
    bool allPinned = true;
    for (int id in _selectedNoteIds) {
      final note = _allNotes.firstWhere((n) => n.id == id);
      if (!note.isPinned) {
        allPinned = false;
        break;
      }
    }
    for (int id in _selectedNoteIds) {
      await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(isPinned: drift.Value(!allPinned))
      );
    }
    _selectedNoteIds.clear();
    await _loadNotes();
  }

  Future<void> toggleArchiveSelectedNotes() async {
    if (_selectedNoteIds.isEmpty) return;
    bool allArchived = true;
    for (int id in _selectedNoteIds) {
      final note = _allNotes.firstWhere((n) => n.id == id);
      if (!note.isArchived) {
        allArchived = false;
        break;
      }
    }
    for (int id in _selectedNoteIds) {
      await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
        NotesCompanion(
          isArchived: drift.Value(!allArchived),
          isPinned: drift.Value(false), // Khi lưu trữ thì bỏ ghim luôn
        )
      );
    }
    _selectedNoteIds.clear();
    await _loadNotes();
  }

  Future<void> addNote(
    String title,
    String content,
    int? color, [
    List<String>? imagePaths,
    bool isChecklist = false,
    List<ChecklistItem>? checklistItems,
    List<String>? tags,
  ]) async {
    final now = DateTime.now();
    
    // Tính toán orderIndex mới (Nối đuôi vào cuối danh sách)
    int newOrderIndex = 0;
    if (_allNotes.isNotEmpty) {
      newOrderIndex = _allNotes.last.orderIndex + 1;
    }
    
    await _db.into(_db.notes).insert(
          NotesCompanion.insert(
            title: title,
            content: content,
            color: drift.Value(color),
            createdAt: drift.Value(now),
            modifiedAt: drift.Value(now),
            orderIndex: drift.Value(newOrderIndex),
            imagePaths: drift.Value(imagePaths),
            isChecklist: drift.Value(isChecklist),
            checklistItems: drift.Value(checklistItems),
            tags: drift.Value(tags),
          ),
        );
    await _loadNotes();
  }

  Future<void> updateNote(
    int id,
    String title,
    String content,
    int? color, [
    List<String>? imagePaths,
    bool? isChecklist,
    List<ChecklistItem>? checklistItems,
    List<String>? tags,
  ]) async {
    final now = DateTime.now();
    
    // Chuẩn bị các giá trị cập nhật
    final companion = NotesCompanion(
      title: drift.Value(title),
      content: drift.Value(content),
      color: drift.Value(color),
      modifiedAt: drift.Value(now),
      imagePaths: drift.Value(imagePaths),
    );
    
    // Map thành Companion hoàn chỉnh nếu có tham số
    final finalCompanion = companion.copyWith(
      isChecklist: isChecklist != null ? drift.Value(isChecklist) : const drift.Value.absent(),
      checklistItems: checklistItems != null ? drift.Value(checklistItems) : const drift.Value.absent(),
      tags: tags != null ? drift.Value(tags) : const drift.Value.absent(),
    );

    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(finalCompanion);
    await _loadNotes();
  }

  Future<void> moveToTrash(int id) async {
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      const NotesCompanion(isDeleted: drift.Value(true))
    );
    await _loadNotes();
  }

  Future<void> restoreNote(int id) async {
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      const NotesCompanion(isDeleted: drift.Value(false))
    );
    await _loadNotes();
  }

  Future<void> permanentlyDeleteNote(int id) async {
    _deleteNoteFiles(id);
    await (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();
    await _loadNotes();
  }

  Future<void> emptyTrash() async {
    final trashNotes = _allNotes.where((n) => n.isDeleted).toList();
    for (var note in trashNotes) {
      _deleteNoteFiles(note.id);
      await (_db.delete(_db.notes)..where((t) => t.id.equals(note.id))).go();
    }
    await _loadNotes();
  }

  Future<void> toggleArchive(int id) async {
    final note = _allNotes.firstWhere((n) => n.id == id);
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isArchived: drift.Value(!note.isArchived),
        isPinned: drift.Value(false), // Xóa ghim khi lưu trữ
      )
    );
    await _loadNotes();
  }
  
  Future<void> updateTags(int id, List<String> tags) async {
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(tags: drift.Value(tags))
    );
    await _loadNotes();
  }

  Future<void> reorderPinnedNotes(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final List<Note> pinned = pinnedNotes;
    final Note draggedItem = pinned.removeAt(oldIndex);
    pinned.insert(newIndex, draggedItem);

    await _updateNotesOrder(pinned, unpinnedNotes);
  }

  Future<void> reorderUnpinnedNotes(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final List<Note> unpinned = unpinnedNotes;
    final Note draggedItem = unpinned.removeAt(oldIndex);
    unpinned.insert(newIndex, draggedItem);

    await _updateNotesOrder(pinnedNotes, unpinned);
  }

  Future<void> _updateNotesOrder(List<Note> pinned, List<Note> unpinned) async {
    _allNotes = [...pinned, ...unpinned];

    // Cập nhật orderIndex cho tất cả
    for (int i = 0; i < _allNotes.length; i++) {
      if (_allNotes[i].orderIndex != i) {
        await (_db.update(_db.notes)..where((t) => t.id.equals(_allNotes[i].id))).write(
          NotesCompanion(orderIndex: drift.Value(i)),
        );
        _allNotes[i] = _allNotes[i].copyWith(orderIndex: i);
      }
    }
  }

  // --- CÁC HÀM TÍNH NĂNG MỚI ---

  // Bật/tắt ghim
  Future<void> togglePin(int id, bool currentPinState) async {
    final now = DateTime.now();
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isPinned: drift.Value(!currentPinState),
        modifiedAt: drift.Value(now),
      ),
    );
    await _loadNotes();
  }

  // Cập nhật màu sắc nhanh
  Future<void> updateColor(int id, int? color) async {
    final now = DateTime.now();
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        color: drift.Value(color),
        modifiedAt: drift.Value(now),
      ),
    );
    await _loadNotes();
  }

  // Hẹn giờ nhắc nhở
  Future<void> setReminder(int id, DateTime? reminderTime) async {
    final now = DateTime.now();
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        reminderAt: drift.Value(reminderTime),
        modifiedAt: drift.Value(now),
      ),
    );
    await _loadNotes();
  }

  // Thêm một hình ảnh vào ghi chú
  Future<void> addImage(int id, String newImagePath) async {
    final note = _allNotes.firstWhere((n) => n.id == id);
    final List<String> currentImages = note.imagePaths != null ? List<String>.from(note.imagePaths!) : [];
    currentImages.add(newImagePath);
    
    final now = DateTime.now();
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        imagePaths: drift.Value(currentImages),
        modifiedAt: drift.Value(now),
      ),
    );
    await _loadNotes();
  }

  // Xóa một hình ảnh khỏi ghi chú
  Future<void> removeImage(int id, String imagePathToRemove) async {
    final note = _allNotes.firstWhere((n) => n.id == id);
    if (note.imagePaths == null) return;
    
    // Xóa file vật lý trên ổ cứng
    try {
      final file = File(imagePathToRemove);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      // Bỏ qua nếu không thể xóa
    }

    final List<String> currentImages = List<String>.from(note.imagePaths!);
    currentImages.remove(imagePathToRemove);
    
    final now = DateTime.now();
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        // Nếu mảng rỗng thì lưu là null để tiết kiệm DB
        imagePaths: drift.Value(currentImages.isEmpty ? null : currentImages),
        modifiedAt: drift.Value(now),
      ),
    );
    await _loadNotes();
  }
}
