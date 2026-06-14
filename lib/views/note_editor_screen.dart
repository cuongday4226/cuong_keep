import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../view_models/notes_view_model.dart';
import '../models/database.dart';

// NoteEditorScreen: Màn hình chỉnh sửa/thêm mới ghi chú
// StatefulWidget là một widget CÓ LƯU TRẠNG THÁI BÊN TRONG NÓ.
// Vì khi ta gõ phím, màn hình phải cập nhật chữ ngay lập tức, hoặc khi ta chọn màu, màu phải đổi liền,
// do đó ta cần dùng StatefulWidget để dùng hàm setState().
class NoteEditorScreen extends StatefulWidget {
  // Biến nhận id ghi chú. Nếu là null thì nghĩa là đang thêm mới. Nếu có số thì nghĩa là đang sửa
  final int? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  // Controller: là biến để điều khiển và lấy giá trị của khung gõ văn bản
  final _titleController = TextEditingController(); // Controller của khung gõ tiêu đề
  final _contentController = TextEditingController(); // Controller của khung gõ nội dung
  
  // Biến lưu giữ màu sắc hiện tại đang chọn
  int? _selectedColor;
  
  // Biến lưu thông tin ghi chú cũ (nếu ta đang sửa)
  Note? _existingNote;

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
  }

  // Hàm tải dữ liệu ghi chú cũ để điền sẵn vào màn hình
  void _loadNote() {
    // Gọi ViewModel để lấy danh sách ghi chú
    final viewModel = context.read<NotesViewModel>();
    try {
      // Tìm đúng ghi chú có id bằng với noteId được truyền vào
      final note = viewModel.notes.firstWhere((n) => n.id == widget.noteId);
      
      // Hàm setState() ra lệnh cho Flutter: "Biến của tao vừa thay đổi đó, hãy vẽ lại giao diện đi!"
      setState(() {
        _existingNote = note; // Lưu đối tượng ghi chú cũ lại
        _titleController.text = note.title; // Đẩy chữ tiêu đề vào khung nhập
        _contentController.text = note.content; // Đẩy chữ nội dung vào khung nhập
        _selectedColor = note.color; // Cập nhật màu
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

  // Hàm lưu ghi chú
  void _saveNote() {
    final title = _titleController.text.trim(); // Lấy chữ ở khung tiêu đề và cắt khoảng trắng 2 đầu
    final content = _contentController.text.trim(); // Lấy chữ ở khung nội dung

    // Nếu cả tiêu đề và nội dung đều trống -> KHÔNG lưu gì cả, thoát hàm
    if (title.isEmpty && content.isEmpty) {
      return;
    }

    final viewModel = context.read<NotesViewModel>();
    // Nếu là ghi chú đã có từ trước (Đang sửa)
    if (_existingNote != null) {
      viewModel.updateNote(_existingNote!.id, title, content, _selectedColor);
    } else {
      // Nếu là ghi chú mới
      viewModel.addNote(title, content, _selectedColor);
    }
  }

  // Hàm xóa ghi chú
  void _deleteNote() {
    if (_existingNote != null) {
      context.read<NotesViewModel>().deleteNote(_existingNote!.id);
    }
    context.pop(); // pop() nghĩa là đóng màn hình hiện tại lại (quay về Trang chủ)
  }

  // Hàm build() chứa toàn bộ giao diện màn hình
  @override
  Widget build(BuildContext context) {
    // PopScope: chặn sự kiện người dùng bấm nút Quay lại (Back)
    return PopScope(
      onPopInvoked: (didPop) {
        if (!didPop) {
          _saveNote(); // Tự động lưu trước khi thoát
          context.pop(); // Thoát màn hình
        }
      },
      canPop: false, // Ngăn hành vi quay lại mặc định để ép chạy hàm onPopInvoked ở trên
      child: Scaffold(
        // Màu nền của nguyên màn hình phụ thuộc vào màu người dùng đã chọn, nếu chưa chọn thì lấy màu mặc định
        backgroundColor: _selectedColor != null ? Color(_selectedColor!) : Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent, // AppBar trong suốt để hòa làm một với màu nền
          elevation: 0, // Không có bóng đổ (làm cho phẳng)
          actions: [
            // Chỉ hiển thị nút Xóa (thùng rác) khi đây là bản sửa của ghi chú cũ
            if (_existingNote != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteNote,
              ),
            // Nút Bảng màu
            IconButton(
              icon: const Icon(Icons.color_lens_outlined),
              onPressed: () {
                _showColorPicker(context); // Mở cửa sổ nhỏ dưới đáy để chọn màu
              },
            ),
            // Nút Dấu tích (lưu thủ công)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                _saveNote();
                context.pop(); // Lưu xong thì quay ra ngoài
              },
            ),
          ],
        ),
        // Phần thân chứa 2 ô điền văn bản
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0), // Căn lề hai bên và trên dưới
          child: Column(
            children: [
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
                child: TextField(
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
    );
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
