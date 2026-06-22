import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/file_utils.dart';

// Class đại diện cho 1 nét vẽ
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  // Dùng để chụp ảnh giao diện
  final GlobalKey _repaintKey = GlobalKey();

  // Danh sách nét vẽ
  final List<DrawingStroke> _strokes = [];
  // Undo stack
  final List<DrawingStroke> _undoStack = [];

  // Trạng thái hiện tại
  Color _penColor = Colors.black;
  double _strokeWidth = 5.0;
  bool _isEraserMode = false;

  // Hình nền và màu nền
  String? _backgroundImagePath;
  Color _backgroundColor = Colors.white;

  // Xử lý vẽ
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _undoStack.clear(); // Xóa lịch sử làm lại khi có nét mới
      _strokes.add(
        DrawingStroke(
          points: [details.localPosition],
          color: _isEraserMode ? Colors.transparent : _penColor,
          width: _strokeWidth,
          isEraser: _isEraserMode,
        ),
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (_strokes.isNotEmpty) {
        _strokes.last.points.add(details.localPosition);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Không làm gì thêm, chỉ cập nhật UI
  }

  // Thay đổi màu bút
  void _changePenColor(Color color) {
    setState(() {
      _penColor = color;
      _isEraserMode = false; // Bấm chọn màu thì tắt cục tẩy
    });
  }

  // Bật chế độ tẩy
  void _toggleEraser() {
    setState(() {
      _isEraserMode = true;
    });
  }

  // Đổi màu nền (Gộp chung)
  Future<void> _pickBackgroundColor() async {
    final colors = [
      Colors.white,
      Colors.black,
      const Color(0xFFFFF9E6), // Giấy ố vàng
      Colors.blue.shade50,
      Colors.green.shade50,
      Colors.pink.shade50,
      Colors.yellow.shade100,
      Colors.grey.shade200,
    ];

    Color? selected = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn màu nền'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((c) {
              return GestureDetector(
                onTap: () => Navigator.pop(context, c),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _backgroundColor = selected;
        _backgroundImagePath = null;
      });
    }
  }

  // Chọn ảnh nền
  Future<void> _pickBackgroundImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _backgroundImagePath = result.files.single.path;
      });
    }
  }

  // Hoàn tác
  void _undo() {
    setState(() {
      if (_strokes.isNotEmpty) {
        _undoStack.add(_strokes.removeLast());
      }
    });
  }

  // Làm lại
  void _redo() {
    setState(() {
      if (_undoStack.isNotEmpty) {
        _strokes.add(_undoStack.removeLast());
      }
    });
  }

  // Xóa sạch
  void _clear() {
    setState(() {
      _strokes.clear();
      _undoStack.clear();
      // Không đổi hình nền hay màu nền, chỉ xóa nét
    });
  }

  // Chụp ảnh từ RepaintBoundary và lưu
  Future<void> _saveDrawing() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        final dir = await FileUtils.getDataDirectory();
        final targetFile = File('${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
        await targetFile.writeAsBytes(bytes);
        
        if (mounted) {
          Navigator.pop(context, targetFile.path);
        }
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
          // Khu vực bảng vẽ bọc trong RepaintBoundary
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                // Nền của bảng vẽ (có thể là màu hoặc ảnh)
                color: _backgroundImagePath == null ? _backgroundColor : null,
                decoration: _backgroundImagePath != null
                    ? BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(File(_backgroundImagePath!)),
                          fit: BoxFit.cover,
                        ),
                      )
                    : null,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: DrawingPainter(strokes: _strokes),
                  ),
                ),
              ),
            ),
          ),
          
          // Khu vực thanh công cụ nằm dưới đáy
          Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hàng trượt độ dày nét bút
                  Row(
                    children: [
                      const Icon(Icons.line_weight, size: 20),
                      Expanded(
                        child: Slider(
                          value: _strokeWidth,
                          min: 1.0,
                          max: 50.0, // Cho phép nét to hơn cho tẩy
                          onChanged: (val) {
                            setState(() {
                              _strokeWidth = val;
                            });
                          },
                        ),
                      ),
                      Text('${_strokeWidth.toInt()} px'),
                    ],
                  ),
                  
                  // Hàng nút thao tác (Hoàn tác, Ảnh nền, Xóa...)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.undo),
                            tooltip: 'Hoàn tác',
                            onPressed: _strokes.isNotEmpty ? _undo : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.redo),
                            tooltip: 'Làm lại',
                            onPressed: _undoStack.isNotEmpty ? _redo : null,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image_outlined),
                            tooltip: 'Chèn ảnh nền',
                            onPressed: _pickBackgroundImage,
                          ),
                          IconButton(
                            icon: const Icon(Icons.format_color_fill),
                            tooltip: 'Chọn màu nền',
                            onPressed: _pickBackgroundColor,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Xóa nét vẽ',
                            onPressed: _strokes.isNotEmpty ? _clear : null,
                          ),
                        ],
                      )
                    ],
                  ),
                  const Divider(height: 8),
                  
                  // Hàng chọn màu bút và cục tẩy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildColorDot(Colors.black),
                      _buildColorDot(Colors.red),
                      _buildColorDot(Colors.blue),
                      _buildColorDot(Colors.green),
                      _buildColorDot(Colors.orange),
                      _buildColorDot(Colors.purple),
                      _buildColorDot(Colors.yellow),
                      _buildColorDot(Colors.brown),
                      // Nút Tẩy
                      IconButton(
                        icon: const Icon(Icons.phonelink_erase),
                        tooltip: 'Cục tẩy',
                        color: _isEraserMode ? Theme.of(context).colorScheme.primary : null,
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

  // Tiện ích tạo ô chọn màu bút
  Widget _buildColorDot(Color color) {
    final isSelected = !_isEraserMode && _penColor == color;
    return GestureDetector(
      onTap: () => _changePenColor(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.grey.shade500, width: 3) : null,
        ),
      ),
    );
  }
}

// Bút vẽ cho CustomPaint
class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    // Lưu lại layer để BlendMode.clear chỉ áp dụng trên lớp mực, không xuyên xuống hình nền ở dưới
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke;

      if (stroke.isEraser) {
        paint.blendMode = BlendMode.clear;
        paint.color = Colors.transparent;
      } else {
        paint.blendMode = BlendMode.srcOver;
        paint.color = stroke.color;
      }

      final path = Path();
      path.moveTo(stroke.points[0].dx, stroke.points[0].dy);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }

      // Xử lý trường hợp chỉ chấm một điểm (dot)
      if (stroke.points.length == 1) {
        path.addOval(Rect.fromCircle(center: stroke.points[0], radius: stroke.width / 4));
        paint.style = PaintingStyle.fill;
      }

      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true; 
  }
}
