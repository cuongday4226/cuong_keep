import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

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
}

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Tăng schemaVersion lên 2 vì ta vừa thêm cột orderIndex
  @override
  int get schemaVersion => 2;

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
