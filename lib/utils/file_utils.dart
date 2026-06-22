import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  static const String dataFolderName = 'Cuong_Keep_Data';

  // Lấy đường dẫn thư mục chứa toàn bộ dữ liệu của app
  static Future<Directory> getDataDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dataDir = Directory(p.join(docDir.path, dataFolderName));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir;
  }

  // Hàm dọn dẹp, di chuyển dữ liệu cũ vào thư mục mới
  static Future<void> migrateOldData() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dataDir = await getDataDirectory();

      // Di chuyển file Database cũ
      final oldDbFile = File(p.join(docDir.path, 'notes_db.sqlite'));
      final newDbFile = File(p.join(dataDir.path, 'notes_db.sqlite'));
      
      if (await oldDbFile.exists() && !await newDbFile.exists()) {
        await oldDbFile.copy(newDbFile.path);
        // Sau khi copy an toàn, xóa file cũ đi cho gọn
        await oldDbFile.delete();
      }

      // Quét tất cả file trong Documents để gom các file ảnh vẽ, ảnh dán vào
      final entities = docDir.listSync(recursive: false);
      for (var entity in entities) {
        if (entity is File) {
          final filename = p.basename(entity.path);
          if (filename.startsWith('drawing_') || filename.startsWith('pasted_image_')) {
            final newFilePath = p.join(dataDir.path, filename);
            if (!await File(newFilePath).exists()) {
              await entity.copy(newFilePath);
              await entity.delete(); // Xóa file rác ở ngoài Documents
            }
          }
        }
      }
    } catch (e) {
      // Bỏ qua lỗi nếu có vấn đề phân quyền
    }
  }
}
