import 'dart:io';
import 'package:drift/native.dart';
import 'lib/models/database.dart';

void main() async {
  final file = File('test.sqlite');
  if (file.existsSync()) file.deleteSync();
  final db = AppDatabase();
  
  await db.into(db.notes).insert(
    NotesCompanion.insert(
      title: 'Test',
      content: 'Test content',
      imagePaths: const drift.Value(['path1', 'path2']),
    ),
  );
  
  final notes = await db.select(db.notes).get();
  print('Notes count: \');
  print('Image paths: \');
  exit(0);
}
