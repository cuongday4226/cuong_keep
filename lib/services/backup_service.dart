import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/notes_view_model.dart';

class BackupService {
  // --- CHỨC NĂNG BACKUP ---
  static Future<void> backupData(BuildContext context) async {
    try {
      final dataDir = await FileUtils.getDataDirectory();

      // Dùng FilePicker.getDirectoryPath thay vì saveFile để tương thích 100% với Windows
      String? selectedDir = await FilePicker.getDirectoryPath(
        dialogTitle: 'Chọn thư mục để lưu bản sao lưu',
      );

      if (selectedDir == null) return; // Người dùng hủy

      if (!context.mounted) return;

      // Hiển thị loading (tùy chọn) vì quá trình nén có thể mất vài giây nếu nhiều ảnh
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Đang tạo bản sao lưu...'),
            ],
          ),
        ),
      );

      // Tạo tên file tự động
      final timestamp = DateTime.now();
      final fileName = 'CuongKeep_Backup_'
          '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_'
          '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}'
          '.backup';
      
      final outputPath = p.join(selectedDir, fileName);
      final tempDir = await Directory.systemTemp.createTemp('cuongkeep_backup_');

      try {
        // Copy toàn bộ dữ liệu (Database + Hình ảnh) sang thư mục tạm
        await _copyDirectory(dataDir, tempDir);

        // Nén thư mục tạm thành file ZIP
        final archive = Archive();
        await for (var entity in tempDir.list(recursive: true)) {
          if (entity is File) {
            final relativePath = p.relative(entity.path, from: tempDir.path);
            final bytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
          }
        }

        final zipData = ZipEncoder().encode(archive);
        final outputFile = File(outputPath);
        
        // ĐẢM BẢO THƯ MỤC CHA TỒN TẠI (Fix lỗi OneDrive trên Windows)
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(zipData, flush: true);

        if (!context.mounted) return;
        Navigator.of(context).pop(); // Tắt loading dialog

        // Hiện SnackBar thành công giống app mẫu của bạn
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sao lưu thành công: $fileName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
      } finally {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Export Error: $e');
      if (context.mounted) {
        try { Navigator.of(context).pop(); } catch (_) {} // Tắt loading nếu đang hiện
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi Sao Lưu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
      }
    }
  }

  // --- CHỨC NĂNG RESTORE ---
  static Future<void> restoreData(BuildContext context) async {
    try {
      // Dùng FilePicker.pickFiles cho Windows
      FilePickerResult? result = await FilePicker.pickFiles(
        dialogTitle: 'Chọn file sao lưu (.backup hoặc .zip)',
        type: FileType.any, // Không dùng allowedExtensions trên Windows vì dễ gây lỗi filter
      );

      if (result != null && result.files.single.path != null) {
        final File selectedFile = File(result.files.single.path!);

        if (!context.mounted) return;

        // Cảnh báo người dùng trước khi đè dữ liệu
        final bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cảnh báo phục hồi'),
            content: const Text(
              'Quá trình này sẽ XÓA SẠCH dữ liệu hiện tại và thay thế bằng dữ liệu trong file sao lưu.\n\n'
              'Bạn có chắc chắn muốn tiếp tục?',
            ),
            actions: [
              OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Phục hồi')),
            ],
          ),
        ) ?? false;

        if (confirm) {
          if (!context.mounted) return;

          // Hiển thị dialog loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Đang phục hồi dữ liệu...'),
                ],
              ),
            ),
          );

          final tempDir = await Directory.systemTemp.createTemp('cuongkeep_restore_');
          try {
            final bytes = await selectedFile.readAsBytes();
            if (bytes.isEmpty) {
              throw Exception('File sao lưu trống rỗng hoặc bị hỏng!');
            }

            final archive = ZipDecoder().decodeBytes(bytes);
            bool hasDatabase = false;

            // Giải nén ra thư mục tạm
            for (final file in archive) {
              if (file.name.contains('notes_db.sqlite')) {
                hasDatabase = true;
              }
              if (file.isFile) {
                final data = file.content as List<int>;
                final destFile = File(p.join(tempDir.path, file.name));
                await destFile.parent.create(recursive: true);
                await destFile.writeAsBytes(data);
              }
            }

            if (!hasDatabase) {
              throw Exception('File này không phải là bản sao lưu hợp lệ của Cuong Keep!');
            }

            if (!context.mounted) return;

            // Đóng Database hiện tại trước khi ghi đè
            await context.read<NotesViewModel>().closeDatabase();

            final dataDir = await FileUtils.getDataDirectory();
            // Xóa dữ liệu cũ
            if (await dataDir.exists()) {
              await dataDir.delete(recursive: true);
            }
            await dataDir.create(recursive: true);

            // Copy toàn bộ dữ liệu (ảnh + database) từ temp sang thư mục thật
            await _copyDirectory(tempDir, dataDir);

            if (context.mounted) {
              // Reload lại Database mà không cần khởi động lại ứng dụng
              await context.read<NotesViewModel>().reloadDatabase();
              
              Navigator.of(context).pop(); // Tắt loading dialog
              
              // Hiện SnackBar thành công
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phục hồi dữ liệu thành công!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  showCloseIcon: true,
                ),
              );
            }
          } finally {
            try {
              await tempDir.delete(recursive: true);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Import Error: $e');
      if (context.mounted) {
        try { Navigator.of(context).pop(); } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi Phục Hồi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
      }
    }
  }

  // Hàm hỗ trợ copy toàn bộ thư mục đệ quy
  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        var newDirectory = Directory(p.join(destination.path, p.basename(entity.path)));
        await newDirectory.create(recursive: true);
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        try {
          await entity.copy(p.join(destination.path, p.basename(entity.path)));
        } catch (e) {
          debugPrint('[BACKUP] Không thể copy ${p.basename(entity.path)}: $e');
        }
      }
    }
  }
}
