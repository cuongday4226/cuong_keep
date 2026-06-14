import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';
import 'package:path_provider/path_provider.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  // Bộ điều khiển bảng vẽ đa sắc
  late ScribbleNotifier _notifier;
  
  // Màu bút hiện tại
  Color _penColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _notifier = ScribbleNotifier();
    _notifier.setColor(_penColor);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  // Hàm thay đổi màu bút (áp dụng cho nét TƯƠNG LAI, không đổi nét trong quá khứ)
  void _changePenColor(Color color) {
    setState(() {
      _penColor = color;
      _notifier.setColor(color);
    });
  }

  // Bật/tắt chế độ tẩy
  void _toggleEraser() {
    setState(() {
      _penColor = Colors.transparent; // Đánh dấu là đang dùng tẩy
      _notifier.setEraser();
    });
  }

  // Hàm xuất bản vẽ ra file PNG và trả về màn hình trước
  Future<void> _saveDrawing() async {
    try {
      // Render bản vẽ thành Image ByteData
      final byteData = await _notifier.renderImage(pixelRatio: 2.0);
      
      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final targetFile = File('${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
      await targetFile.writeAsBytes(bytes);
      
      if (mounted) {
        // Trả file ảnh về màn hình Ghi chú
        Navigator.pop(context, targetFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi lưu bản vẽ!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản vẽ đa sắc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Lưu bản vẽ',
            onPressed: _saveDrawing,
          ),
        ],
      ),
      body: Column(
        children: [
          // Khu vực bảng vẽ
          Expanded(
            child: Container(
              color: Colors.white, // Giấy trắng
              child: Scribble(
                notifier: _notifier,
                drawPen: true, // Hỗ trợ bút cảm ứng
              ),
            ),
          ),
          // Thanh công cụ dưới đáy
          Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hàng nút Hoàn tác và Xóa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.undo),
                            tooltip: 'Hoàn tác',
                            onPressed: () => _notifier.canUndo ? _notifier.undo() : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.redo),
                            tooltip: 'Làm lại',
                            onPressed: () => _notifier.canRedo ? _notifier.redo() : null,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Xóa toàn bộ',
                        onPressed: () => _notifier.clear(),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Hàng chọn màu và tẩy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildColorDot(Colors.black),
                      _buildColorDot(Colors.red),
                      _buildColorDot(Colors.blue),
                      _buildColorDot(Colors.green),
                      _buildColorDot(Colors.orange),
                      _buildColorDot(Colors.purple),
                      // Nút Tẩy
                      IconButton(
                        icon: const Icon(Icons.phonelink_erase),
                        tooltip: 'Cục tẩy',
                        color: _penColor == Colors.transparent ? Theme.of(context).colorScheme.primary : null,
                        onPressed: _toggleEraser,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tiện ích tạo ô chọn màu
  Widget _buildColorDot(Color color) {
    final isSelected = _penColor == color;
    return GestureDetector(
      onTap: () => _changePenColor(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.grey.shade500, width: 3) : null,
        ),
      ),
    );
  }
}
