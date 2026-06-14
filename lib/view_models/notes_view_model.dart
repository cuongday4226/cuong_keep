import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:async';
import '../models/database.dart';
import '../services/notification_service.dart';

class NotesViewModel extends ChangeNotifier {
  final AppDatabase _db;
  List<Note> _notes = [];
  String _searchQuery = '';
  Timer? _reminderTimer;

  List<Note> get notes => _notes;
  String get searchQuery => _searchQuery;

  NotesViewModel(this._db) {
    _loadNotes();
    _startReminderTimer();
  }

  void _startReminderTimer() {
    // Cứ mỗi 30 giây kiểm tra 1 lần xem có báo thức nào tới hạn chưa
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final now = DateTime.now();
      for (var note in _notes) {
        if (note.reminderAt != null) {
          // Báo thức được tính là tới hạn nếu giờ hiện tại lớn hơn hoặc bằng giờ báo thức
          final diff = now.difference(note.reminderAt!);
          // Kiểm tra diff trong khoảng 0 đến 60 giây để tránh bắn thông báo nhiều lần hoặc bị lỡ
          if (diff.inSeconds >= 0 && diff.inMinutes < 2) {
            await NotificationService().showNotification(
              id: note.id,
              title: 'Nhắc nhở: ${note.title.isNotEmpty ? note.title : "Ghi chú"}',
              body: note.content,
            );
            // Sau khi thông báo, xóa hẹn giờ đi
            await setReminder(note.id, null);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
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

    // Lọc theo từ khóa (LIKE)
    if (_searchQuery.isNotEmpty) {
      query.where((t) => t.title.like('%$_searchQuery%') | t.content.like('%$_searchQuery%'));
    }

    _notes = await query.get();
    notifyListeners();
  }

  Future<void> addNote(String title, String content, int? color, [List<String>? imagePaths]) async {
    final now = DateTime.now();
    
    // Tính toán orderIndex mới (Nối đuôi vào cuối danh sách)
    int newOrderIndex = 0;
    if (_notes.isNotEmpty) {
      newOrderIndex = _notes.last.orderIndex + 1;
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
          ),
        );
    await _loadNotes();
  }

  Future<void> updateNote(int id, String title, String content, int? color, [List<String>? imagePaths]) async {
    final now = DateTime.now();
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        title: drift.Value(title),
        content: drift.Value(content),
        color: drift.Value(color),
        modifiedAt: drift.Value(now),
        imagePaths: drift.Value(imagePaths),
      ),
    );
    await _loadNotes();
  }

  Future<void> deleteNote(int id) async {
    await (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();
    await _loadNotes();
  }

  // Hàm xử lý hoán đổi vị trí ghi chú khi kéo thả (Reorder)
  Future<void> reorderNotes(int oldIndex, int newIndex) async {
    // Theo tài liệu của ReorderableGridView, khi kéo thả từ trên xuống thì newIndex bị lệch 1 đơn vị
    // Ta trừ đi 1 để bù trừ sự sai lệch đó
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // Nếu vẫn ở vị trí cũ thì bỏ qua
    if (oldIndex == newIndex) return;

    // Lấy phần tử đang được kéo thả (remove khỏi vị trí cũ)
    final Note draggedItem = _notes.removeAt(oldIndex);
    // Chèn nó vào vị trí mới mà người dùng vừa thả ra
    _notes.insert(newIndex, draggedItem);
    
    // Cập nhật lại giao diện NGAY LẬP TỨC để thao tác vuốt thả được mượt mà, không bị lag chờ database
    notifyListeners();

    // Bước tiếp theo: Cập nhật biến orderIndex của các ghi chú bị thay đổi vị trí xuống cơ sở dữ liệu SQLite
    for (int i = 0; i < _notes.length; i++) {
      // Chỉ cập nhật những ô có thứ tự orderIndex khác với số index thực tế của nó
      if (_notes[i].orderIndex != i) {
        // Cập nhật trong DB
        await (_db.update(_db.notes)..where((t) => t.id.equals(_notes[i].id))).write(
          NotesCompanion(orderIndex: drift.Value(i)),
        );
        // Cập nhật lại mảng dữ liệu tạm trên RAM (dùng copyWith để sinh ra bản sao có orderIndex mới)
        _notes[i] = _notes[i].copyWith(orderIndex: i);
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
    final note = _notes.firstWhere((n) => n.id == id);
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
    final note = _notes.firstWhere((n) => n.id == id);
    if (note.imagePaths == null) return;
    
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
