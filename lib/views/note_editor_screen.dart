import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../view_models/notes_view_model.dart';
import '../models/database.dart';
import '../utils/color_utils.dart';
import '../utils/string_utils.dart';
import '../widgets/checklist_item_widget.dart';

// NoteEditorScreen: Màn hình chỉnh sửa/thêm mới ghi chú
// StatefulWidget là một widget CÓ LƯU TRẠNG THÁI BÊN TRONG NÓ.
// Vì khi ta gõ phím, màn hình phải cập nhật chữ ngay lập tức, hoặc khi ta chọn màu, màu phải đổi liền,
// do đó ta cần dùng StatefulWidget để dùng hàm setState().
class NoteEditorScreen extends StatefulWidget {
  // Biến nhận id ghi chú. Nếu là null thì nghĩa là đang thêm mới. Nếu có số thì nghĩa là đang sửa
  final int? noteId;
  final bool startWithDrawing;
  final bool startWithChecklist;

  const NoteEditorScreen({super.key, this.noteId, this.startWithDrawing = false, this.startWithChecklist = false});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  // Controller: là biến để điều khiển và lấy giá trị của khung gõ văn bản
  final _titleController = TextEditingController(); // Controller của khung gõ tiêu đề
  final _contentController = TextEditingController(); // Controller của khung gõ nội dung
  
  // Biến lưu màu sắc hiện tại đang chọn
  int? _selectedColor;

  // Biến lưu mảng danh sách các đường dẫn hình ảnh của ghi chú
  List<String> _imagePaths = [];
  
  // Biến lưu thông tin ghi chú cũ (nếu ta đang sửa)
  Note? _existingNote;

  // Biến cho tính năng Checklist
  bool _isChecklist = false;
  List<ChecklistItem> _checklistItems = [];

  // Danh sách các màu nền để người dùng chọn (chữ ".shade100" làm cho màu nhạt đi, đẹp mắt hơn cho nền)
  final List<Color> _colors = [
    Colors.transparent, // Không màu (trong suốt - mặc định)
    Colors.red.shade100,
    Colors.green.shade100,
    Colors.blue.shade100,
    Colors.yellow.shade100,
    Colors.purple.shade100,
    Colors.orange.shade100,
  ];

  // Hàm initState() chạy đúng 1 lần DUY NHẤT khi màn hình này vừa được mở lên
  @override
  void initState() {
    super.initState();
    // Nếu có noteId (tức là đang sửa ghi chú cũ)
    if (widget.noteId != null) {
      // Đợi giao diện (context) dựng xong thì gọi _loadNote() để tải dữ liệu ghi chú cũ vào khung gõ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNote();
      });
    }
    
    // Nếu người dùng bấm tạo ghi chú có bản vẽ từ màn hình chính
    if (widget.startWithDrawing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openDrawingScreen();
      });
    }

    // Nếu người dùng bấm tạo danh sách từ màn hình chính
    if (widget.startWithChecklist) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isChecklist = true;
          _checklistItems = [ChecklistItem(id: DateTime.now().microsecondsSinceEpoch.toString(), text: '')];
        });
      });
    }
  }

  // Hàm tải dữ liệu ghi chú cũ để điền sẵn vào màn hình
  void _loadNote() {
    // Gọi ViewModel để lấy danh sách ghi chú
    final viewModel = context.read<NotesViewModel>();
    try {
      // Tìm đúng ghi chú có id bằng với noteId được truyền vào
      final note = viewModel.notes.firstWhere((n) => n.id == widget.noteId);
      
      setState(() {
        _existingNote = note; // Lưu đối tượng ghi chú cũ lại
        _titleController.text = note.title; // Đẩy chữ tiêu đề vào khung nhập
        _contentController.text = note.content; // Đẩy chữ nội dung vào khung nhập
        _selectedColor = note.color; // Cập nhật màu
        _imagePaths = note.imagePaths != null ? List<String>.from(note.imagePaths!) : []; // Cập nhật danh sách ảnh
        _isChecklist = note.isChecklist;
        _checklistItems = note.checklistItems != null ? List<ChecklistItem>.from(note.checklistItems!) : [];
      });
    } catch (e) {
      // Không tìm thấy ghi chú (tránh lỗi)
    }
  }

  // Hàm dispose() chạy đúng 1 lần khi màn hình này bị đóng đi (như khi bấm nút quay lại)
  // Đây là nơi bắt buộc phải "hủy" các Controller đi để giải phóng RAM cho máy tính
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  // Hàm lưu ghi chú và thoát
  Future<void> _saveNoteAndPop() async {
    if (_isSaving) return;
    _isSaving = true;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Nếu cả tiêu đề, nội dung và ảnh đều trống -> KHÔNG lưu gì cả
    bool isChecklistEmpty = _checklistItems.isEmpty || _checklistItems.every((e) => e.text.trim().isEmpty);
    if (title.isEmpty && content.isEmpty && _imagePaths.isEmpty && isChecklistEmpty) {
      if (mounted) context.pop();
      return;
    }

    final viewModel = context.read<NotesViewModel>();
    final pathsToSave = _imagePaths.isEmpty ? null : _imagePaths;
    
    // Loại bỏ các ô checklist trống rỗng trước khi lưu
    final itemsToSave = _checklistItems.where((e) => e.text.trim().isNotEmpty).toList();
    
    try {
      // Nếu là ghi chú đã có từ trước (Đang sửa)
      if (_existingNote != null) {
        await viewModel.updateNote(_existingNote!.id, title, content, _selectedColor, pathsToSave, _isChecklist, itemsToSave);
      } else {
        // Nếu là ghi chú mới
        await viewModel.addNote(title, content, _selectedColor, pathsToSave, _isChecklist, itemsToSave);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: Vui lòng khởi động lại ứng dụng hoàn toàn (Tắt ở System Tray).')),
        );
      }
    }

    if (mounted) {
      context.pop();
    }
  }

  // Hàm xóa ghi chú
  void _deleteNote() {
    if (_existingNote != null) {
      context.read<NotesViewModel>().deleteNote(_existingNote!.id);
    }
    context.pop();
  }

  // Hàm chuyển đổi qua lại giữa Văn bản và Danh sách (Checklist)
  void _toggleChecklistMode() {
    setState(() {
      _isChecklist = !_isChecklist;
      if (_isChecklist) {
        // Chuyển từ Text sang Checklist
        if (_contentController.text.isNotEmpty) {
          _checklistItems = _contentController.text.split('\n').where((s) => s.isNotEmpty).map((line) {
            return ChecklistItem(
              id: DateTime.now().microsecondsSinceEpoch.toString() + line.hashCode.toString(),
              text: line,
            );
          }).toList();
        }
      } else {
        // Chuyển từ Checklist sang Text
        _contentController.text = _checklistItems.where((e) => e.text.isNotEmpty).map((e) => e.text).join('\n');
      }
    });
  }

  // Hàm xây dựng giao diện Danh sách kiểm tra (Checklist)
  Widget _buildChecklistUI() {
    final unchecked = _checklistItems.where((e) => !e.isCompleted).toList();
    final checked = _checklistItems.where((e) => e.isCompleted).toList();

    return ListView(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false, // Tự xử lý nút kéo thả
          itemCount: unchecked.length,
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            setState(() {
              final item = unchecked.removeAt(oldIndex);
              unchecked.insert(newIndex, item);
              _checklistItems = [...unchecked, ...checked];
            });
          },
          itemBuilder: (context, index) {
            final item = unchecked[index];
            return ReorderableDragStartListener(
              key: ValueKey(item.id),
              index: index,
              child: ChecklistItemWidget(
                item: item,
                onChanged: (text) => item.text = text,
                onToggle: () {
                  setState(() {
                    item.isCompleted = true;
                    // Chuyển xuống danh sách hoàn thành và sắp xếp ABC
                    _checklistItems = [...unchecked.where((e) => e != item), item, ...checked];
                    _checklistItems.sort((a, b) {
                      if (a.isCompleted == b.isCompleted) {
                        return StringUtils.removeDiacritics(a.text.toLowerCase())
                            .compareTo(StringUtils.removeDiacritics(b.text.toLowerCase()));
                      }
                      return a.isCompleted ? 1 : -1;
                    });
                  });
                },
                onSubmitted: () {
                  setState(() {
                    // Thêm 1 ô trống ngay dưới ô hiện tại
                    final newItem = ChecklistItem(id: DateTime.now().microsecondsSinceEpoch.toString(), text: '');
                    final insertIndex = _checklistItems.indexOf(item) + 1;
                    _checklistItems.insert(insertIndex, newItem);
                  });
                },
                onDeleted: () {
                  setState(() => _checklistItems.remove(item));
                },
                autofocus: item.text.isEmpty,
              ),
            );
          },
        ),
        // Nút thêm mục mới (Luôn nằm dưới các mục chưa check)
        ListTile(
          leading: const Padding(
            padding: EdgeInsets.only(left: 36), // Căn ngang với ô text
            child: Icon(Icons.add, color: Colors.grey),
          ),
          title: const Text('Mục danh sách', style: TextStyle(color: Colors.grey)),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            setState(() {
              _checklistItems.insert(
                unchecked.length,
                ChecklistItem(id: DateTime.now().microsecondsSinceEpoch.toString(), text: '')
              );
            });
          },
        ),
        // Danh sách đã check
        if (checked.isNotEmpty) ...[
          const Divider(),
          ExpansionTile(
            title: Text('${checked.length} mục đã hoàn thành', style: const TextStyle(fontSize: 14)),
            initiallyExpanded: true,
            children: checked.map((item) {
              return ChecklistItemWidget(
                key: ValueKey(item.id),
                item: item,
                onChanged: (text) => item.text = text,
                onToggle: () {
                  setState(() {
                    item.isCompleted = false;
                    _checklistItems.remove(item);
                    _checklistItems.insert(unchecked.length, item); // Bay lên trên
                    // Sắp xếp lại
                    _checklistItems.sort((a, b) {
                      if (a.isCompleted == b.isCompleted) {
                        return StringUtils.removeDiacritics(a.text.toLowerCase())
                            .compareTo(StringUtils.removeDiacritics(b.text.toLowerCase()));
                      }
                      return a.isCompleted ? 1 : -1;
                    });
                  });
                },
                onSubmitted: () {},
                onDeleted: () {
                  setState(() => _checklistItems.remove(item));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // Hàm build() chứa toàn bộ giao diện màn hình
  @override
  Widget build(BuildContext context) {
    // PopScope: chặn sự kiện người dùng bấm nút Quay lại (Back)
    return PopScope(
      onPopInvoked: (didPop) {
        if (!didPop) {
          _saveNoteAndPop(); // Tự động lưu và thoát
        }
      },
      canPop: false, // Ngăn hành vi quay lại mặc định để ép chạy hàm onPopInvoked ở trên
      child: Scaffold(
        // Màu nền của nguyên màn hình phụ thuộc vào màu người dùng đã chọn
        backgroundColor: ColorUtils.getAdaptiveColor(context, _selectedColor),
        appBar: AppBar(
          backgroundColor: Colors.transparent, // AppBar trong suốt để hòa làm một với màu nền
          elevation: 0, // Không có bóng đổ (làm cho phẳng)
          actions: [
            // Nút Bật/tắt hộp kiểm
            IconButton(
              icon: Icon(_isChecklist ? Icons.check_box_outlined : Icons.add_box_outlined),
              tooltip: _isChecklist ? 'Ẩn hộp kiểm' : 'Hiển thị hộp kiểm',
              onPressed: _toggleChecklistMode,
            ),
            // Chỉ hiển thị nút Xóa (thùng rác) khi đây là bản sửa của ghi chú cũ
            if (_existingNote != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteNote,
              ),
            // Nút Bảng màu được dời xuống thanh BottomAppBar bên dưới
            // Nút Dấu tích (lưu thủ công)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _saveNoteAndPop(),
            ),
          ],
        ),
        // Phần thân chứa ảnh và 2 ô điền văn bản
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            // Lắng nghe tổ hợp phím Ctrl + V
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.keyV &&
                HardwareKeyboard.instance.isControlPressed) {
              _pasteImage();
              // Trả về ignored để TextField vẫn tiếp tục xử lý việc dán TEXT bình thường
              return KeyEventResult.ignored;
            }
            return KeyEventResult.ignored;
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hiển thị danh sách ảnh nếu có
                    if (_imagePaths.isNotEmpty)
                      SizedBox(
                        height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, index) {
                      final path = _imagePaths[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 16, bottom: 16),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(path),
                                fit: BoxFit.contain,
                                height: 200,
                              ),
                            ),
                            // Nút xóa ảnh
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.black54),
                              onPressed: () {
                                setState(() {
                                  _imagePaths.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              // TextField là widget tạo ô điền chữ (Ô tiêu đề)
              TextField(
                controller: _titleController,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), // Chữ bự, in đậm
                decoration: const InputDecoration(
                  hintText: 'Tiêu đề', // Chữ mờ khi chưa gõ gì
                  border: InputBorder.none, // Xóa hoàn toàn viền, tạo cảm giác borderless như Google Keep
                ),
                maxLines: null, // Nhập bao nhiêu dòng cũng được
                textInputAction: TextInputAction.next, // Bấm Enter sẽ chuyển xuống ô dưới
              ),
              // Expanded giúp khung nội dung chiếm toàn bộ phần diện tích màn hình còn lại phía dưới
              Expanded(
                child: _isChecklist
                    ? _buildChecklistUI()
                    : TextField(
                        controller: _contentController, // Khung nội dung
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'Ghi chú...',
                          border: InputBorder.none, // Tương tự, không viền
                        ),
                        maxLines: null, // Gõ xuống dòng thoải mái
                        keyboardType: TextInputType.multiline, // Bật bàn phím phù hợp để gõ nhiều dòng
                      ),
              ),
            ],
          ),
          ),
          ),
          ),
        ),
        // THANH CÔNG CỤ BOTTOM APP BAR
        bottomNavigationBar: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          child: Row(
            children: [
              // Nút Đổi màu
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'Đổi màu nền',
                onPressed: () => _showColorPicker(context),
              ),
              // Nút Chọn Ảnh từ máy
              IconButton(
                icon: const Icon(Icons.image_outlined),
                tooltip: 'Thêm ảnh',
                onPressed: _pickImage,
              ),
              // Nút Dán Ảnh từ Clipboard
              IconButton(
                icon: const Icon(Icons.content_paste),
                tooltip: 'Dán ảnh (Ctrl+V)',
                onPressed: _pasteImage,
              ),
              // Nút Vẽ tay
              IconButton(
                icon: const Icon(Icons.brush_outlined),
                tooltip: 'Bản vẽ mới',
                onPressed: _openDrawingScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm chọn file ảnh từ máy tính
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imagePaths.add(result.files.single.path!);
      });
    }
  }

  // Hàm mở màn hình Bảng vẽ
  Future<void> _openDrawingScreen() async {
    final result = await context.push('/drawing');
    if (result != null && result is String) {
      setState(() {
        _imagePaths.add(result);
      });
    }
  }

  // Hàm dán ảnh từ bộ nhớ tạm (Clipboard)
  Future<void> _pasteImage() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return;
      
      final reader = await clipboard.read();

      // 1. THỬ LẤY ẢNH TRỰC TIẾP (Khi copy ảnh từ web, snipping tool, hoặc file ảnh từ File Explorer)
      if (reader.canProvide(Formats.png)) {
        reader.getFile(Formats.png, (file) async {
          final imageBytes = await file.readAll();
          final dir = await getApplicationDocumentsDirectory();
          final targetFile = File('${dir.path}/pasted_image_${DateTime.now().millisecondsSinceEpoch}.png');
          await targetFile.writeAsBytes(imageBytes);
          
          if (mounted) {
            setState(() { _imagePaths.add(targetFile.path); });
          }
        });
        return;
      }
      
      // 2. THỬ LẤY ẢNH JPEG 
      if (reader.canProvide(Formats.jpeg)) {
        reader.getFile(Formats.jpeg, (file) async {
          final imageBytes = await file.readAll();
          final dir = await getApplicationDocumentsDirectory();
          final targetFile = File('${dir.path}/pasted_image_${DateTime.now().millisecondsSinceEpoch}.jpeg');
          await targetFile.writeAsBytes(imageBytes);
          
          if (mounted) {
            setState(() { _imagePaths.add(targetFile.path); });
          }
        });
        return;
      }

      // Nếu có lỗi nghiêm trọng thì mới hiện thông báo
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi dán ảnh: $e')));
      }
    }
  }

  // Hàm tạo cái bảng nhỏ trượt từ dưới lên (BottomSheet) để chọn màu
  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 120,
          // ListView.builder vẽ các màu thành một danh sách có thể vuốt ngang
          child: ListView.builder(
            scrollDirection: Axis.horizontal, // Cuộn ngang
            itemCount: _colors.length, // Lấy số lượng màu trong danh sách _colors
            itemBuilder: (context, index) {
              final color = _colors[index]; // Lấy từng màu ra
              final isTransparent = color == Colors.transparent; // Kiểm tra xem đây có phải là màu mặc định không
              
              // GestureDetector giúp bắt sự kiện chạm vào ô màu
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // Nếu là trong suốt -> lưu biến màu là null, ngược lại lưu mã số của màu đó
                    _selectedColor = isTransparent ? null : color.value;
                  });
                  Navigator.pop(context); // Chọn màu xong tự động ẩn bảng màu đi
                },
                child: Container(
                  width: 60, height: 60, // Kích thước cục màu tròn
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isTransparent ? Theme.of(context).scaffoldBackgroundColor : color,
                    shape: BoxShape.circle, // Định hình cái viền thành hình tròn
                    border: Border.all(
                      // Nếu cục màu đang vẽ chính là màu được chọn -> Tô viền màu sáng (màu primary) lên để làm nổi bật
                      color: _selectedColor == (isTransparent ? null : color.value)
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  // Nếu ô này là màu trong suốt, ta chèn icon gạch ngang để biểu thị việc "hủy màu"
                  child: isTransparent
                      ? const Icon(Icons.format_color_reset, color: Colors.grey)
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
