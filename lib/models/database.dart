import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import '../utils/file_utils.dart';

part 'database.g.dart';

// Converter giúp biến mảng danh sách List<String> thành chuỗi JSON để có thể lưu vào SQLite (vốn chỉ hỗ trợ TEXT)
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final decoded = json.decode(fromDb) as List;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      // Đề phòng trường hợp lỗi parse, coi như mảng rỗng
      return [];
    }
  }

  @override
  String toSql(List<String> value) {
    if (value.isEmpty) return '';
    return json.encode(value);
  }
}

// Model cho từng mục Checklist
class ChecklistItem {
  final String id;
  String text;
  bool isCompleted;

  ChecklistItem({required this.id, required this.text, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isCompleted': isCompleted,
  };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
    text: json['text'] as String? ?? '',
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

// Converter giúp biến mảng ChecklistItem thành JSON lưu vào DB
class ChecklistConverter extends TypeConverter<List<ChecklistItem>, String> {
  const ChecklistConverter();

  @override
  List<ChecklistItem> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final decoded = json.decode(fromDb) as List;
      return decoded.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  String toSql(List<ChecklistItem> value) {
    if (value.isEmpty) return '';
    final list = value.map((e) => e.toJson()).toList();
    return json.encode(list);
  }
}

// Bảng Notes: Định nghĩa cấu trúc của bảng ghi chú trong cơ sở dữ liệu SQLite
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 0, max: 255)();
  TextColumn get content => text()();
  IntColumn get color => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get modifiedAt => dateTime().withDefault(currentDateAndTime)();
  
  // Cột mới: orderIndex dùng để lưu thứ tự vị trí khi kéo thả (Mặc định là 0)
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  // Các cột mới cho tính năng Nâng cao (Schema version 3)
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))(); // Trạng thái Ghim
  DateTimeColumn get reminderAt => dateTime().nullable()(); // Hẹn giờ nhắc nhở
  
  // (Schema version 4): Thay đổi imagePath (ảnh đơn) thành imagePaths (nhiều ảnh)
  TextColumn get imagePaths => text().map(const StringListConverter()).nullable()(); // Mảng đường dẫn ảnh
  
  // (Schema version 5): Các cột cho tính năng Danh sách (Checklist)
  BoolColumn get isChecklist => boolean().withDefault(const Constant(false))(); // Xác định có phải là checklist không
  TextColumn get checklistItems => text().map(const ChecklistConverter()).nullable()(); // Mảng các mục checklist

  // (Schema version 6): Các cột cho Navigation Drawer
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))(); // Cờ thùng rác
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))(); // Cờ lưu trữ
  TextColumn get tags => text().map(const StringListConverter()).nullable()(); // Danh sách nhãn
}

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Tăng schemaVersion lên 6 vì ta vừa thêm các cột cho tính năng Navigation Drawer
  @override
  int get schemaVersion => 6;

  // Xử lý di chuyển dữ liệu (Migration) khi nâng cấp phiên bản Database
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Khi người dùng nâng cấp từ version 1 lên 2, lệnh này sẽ tự động chèn cột orderIndex vào bảng cũ
          // để không làm mất dữ liệu ghi chú cũ của họ.
          await m.addColumn(notes, notes.orderIndex);
        }
        if (from < 3) {
          // Nâng cấp từ version 2 lên 3: Thêm các cột Ghim, Nhắc nhở, Hình ảnh đơn
          await m.addColumn(notes, notes.isPinned);
          await m.addColumn(notes, notes.reminderAt);
        }
        if (from < 4) {
          // Nâng cấp từ version 3 lên 4: Thêm mảng hình ảnh
          await m.addColumn(notes, notes.imagePaths);
        }
        if (from < 5) {
          // Nâng cấp từ version 4 lên 5: Thêm tính năng Checklist
          await m.addColumn(notes, notes.isChecklist);
          await m.addColumn(notes, notes.checklistItems);
        }
        if (from < 6) {
          // Nâng cấp từ version 5 lên 6: Thêm Thùng rác, Lưu trữ và Nhãn
          await m.addColumn(notes, notes.isDeleted);
          await m.addColumn(notes, notes.isArchived);
          await m.addColumn(notes, notes.tags);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await FileUtils.getDataDirectory();
    final file = File(p.join(dbFolder.path, 'notes_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
