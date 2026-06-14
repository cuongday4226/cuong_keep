import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
}

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Tăng schemaVersion lên 4 vì ta vừa đổi imagePath thành mảng imagePaths
  @override
  int get schemaVersion => 4;

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
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'notes_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
