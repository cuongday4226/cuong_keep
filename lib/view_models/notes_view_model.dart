import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../models/database.dart';

class NotesViewModel extends ChangeNotifier {
  final AppDatabase _db;
  List<Note> _notes = [];

  List<Note> get notes => _notes;

  NotesViewModel(this._db) {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    _notes = await (_db.select(_db.notes)
          // Sắp xếp ghi chú theo orderIndex thay vì thời gian sửa (để hỗ trợ tính năng kéo thả)
          ..orderBy([(t) => drift.OrderingTerm(expression: t.orderIndex, mode: drift.OrderingMode.asc)]))
        .get();
    notifyListeners();
  }

  Future<void> addNote(String title, String content, int? color) async {
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
          ),
        );
    await _loadNotes();
  }

  Future<void> updateNote(int id, String title, String content, int? color) async {
    final now = DateTime.now();
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        title: drift.Value(title),
        content: drift.Value(content),
        color: drift.Value(color),
        modifiedAt: drift.Value(now),
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
}
