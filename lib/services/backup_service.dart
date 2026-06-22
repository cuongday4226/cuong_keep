import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/notes_view_model.dart';

class BackupService {
  // Xuất dữ liệu (Backup)
  static Future<void> backupData(BuildContext context) async {
    try {
      final dataDir = await FileUtils.getDataDirectory();
      
      // Chọn nơi lưu file zip
      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Chọn nơi lưu bản sao lưu',
        fileName: 'CuongKeep_Backup_${DateTime.now().millisecondsSinceEpoch}.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (outputFile == null) return; // Người dùng hủy

      if (!context.mounted) return;

      // ĐÓNG KẾT NỐI DATABASE TRƯỚC KHI NÉN (Nếu không Windows sẽ báo lỗi File Locked)
      await context.read<NotesViewModel>().closeDatabase();

      // Nén thư mục
      var encoder = ZipFileEncoder();
      encoder.zipDirectory(dataDir, filename: outputFile);
      
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Sao lưu thành công!'),
            content: Text('Dữ liệu đã được lưu tại: $outputFile\n\nỨng dụng cần khởi động lại để tiếp tục sử dụng.'),
            actions: [
              TextButton(
                onPressed: () => exit(0),
                child: const Text('Đóng ứng dụng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi sao lưu: $e')),
        );
      }
    }
  }

  // Nhập dữ liệu (Restore)
  static Future<void> restoreData(BuildContext context) async {
    try {
      // Chọn file zip để phục hồi
      FilePickerResult? result = await FilePicker.pickFiles(
        dialogTitle: 'Chọn file sao lưu (.zip)',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) return; // Người dùng hủy

      final zipFile = File(result.files.single.path!);
      final dataDir = await FileUtils.getDataDirectory();

      if (!context.mounted) return;

      // Cảnh báo người dùng trước khi ghi đè
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cảnh báo phục hồi'),
          content: const Text('Quá trình này sẽ xóa sạch dữ liệu hiện tại và thay thế bằng dữ liệu trong file sao lưu. Bạn có chắc chắn muốn tiếp tục?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Phục hồi', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (!context.mounted) return;

      // ĐÓNG DATABASE TRƯỚC KHI GHI ĐÈ
      await context.read<NotesViewModel>().closeDatabase();

      // Xóa toàn bộ nội dung trong thư mục dataDir (ẩn và lộ)
      if (await dataDir.exists()) {
        await dataDir.delete(recursive: true);
      }
      await dataDir.create(recursive: true);

      // Giải nén
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final destFile = File(p.join(dataDir.path, filename));
          // Tạo thư mục nếu cần thiết (dù zipDirectory thường nén thẳng file nếu thư mục không sâu)
          await destFile.parent.create(recursive: true);
          await destFile.writeAsBytes(data);
        }
      }

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Phục hồi thành công!'),
            content: const Text('Ứng dụng cần khởi động lại để tải dữ liệu mới. Vui lòng tắt ứng dụng và mở lại.'),
            actions: [
              TextButton(
                onPressed: () {
                  exit(0); // Tắt app
                },
                child: const Text('Đóng ứng dụng'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi phục hồi: $e')),
        );
      }
    }
  }
}
