import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../view_models/notes_view_model.dart';
import '../view_models/theme_view_model.dart';
import 'package:intl/intl.dart';

// Đổi từ StatelessWidget sang StatefulWidget để có thể quản lý trạng thái của Navigation Drawer
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Biến lưu trữ mục nào đang được chọn trong ngăn kéo (0 = Ghi chú, mặc định)
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- THANH TRƯỢT BÊN TRÁI (NAVIGATION DRAWER) ---
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
          // Tự động đóng Drawer sau khi chọn (trên thiết bị hẹp)
          Navigator.pop(context);
        },
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Cuong Keep',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: Text('Ghi chú'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: Text('Lời nhắc'),
          ),
          Divider(indent: 28, endIndent: 28),
          Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Nhãn',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          // Có thể thêm các mục Nhãn ở đây sau này
          Divider(indent: 28, endIndent: 28),
          NavigationDrawerDestination(
            icon: Icon(Icons.archive_outlined),
            selectedIcon: Icon(Icons.archive),
            label: Text('Lưu trữ'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.delete_outline),
            selectedIcon: Icon(Icons.delete),
            label: Text('Thùng rác'),
          ),
        ],
      ),
      appBar: AppBar(
        // Tiêu đề bây giờ là một thanh Tìm kiếm (Search bar)
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            // Màu nền của thanh tìm kiếm (hơi xám)
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none, // Xóa gạch chân mặc định của TextField
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Căn giữa chữ
            ),
          ),
        ),
        actions: [
          // Nút Tải lại (Reload)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () {
              // TODO: Tính năng làm mới dữ liệu
            },
          ),
          // Nút Chế độ xem (List/Grid)
          IconButton(
            icon: const Icon(Icons.view_agenda_outlined), // Biểu tượng dạng danh sách (hoặc dùng grid_view)
            tooltip: 'Chế độ xem danh sách',
            onPressed: () {
              // TODO: Tính năng chuyển đổi giữa lưới và danh sách
            },
          ),
          // Nút Cài đặt (Mở cửa sổ Cài đặt tổng hợp)
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () {
              _showSettingsDialog(context);
            },
          ),
          const SizedBox(width: 8), // Khoảng trống nhỏ bên phải cùng
        ],
      ),
      // Dùng IndexedStack để hiển thị giao diện tùy theo mục Drawer được chọn
      // Nếu _selectedIndex == 0 (Ghi chú), hiện Lưới ghi chú. Còn lại hiện dòng chữ Tạm trống.
      body: _selectedIndex == 0 ? _buildNotesGrid() : _buildPlaceholderScreen(),
    );
  }

  // Widget riêng dành cho giao diện chính của phần Ghi chú (đã làm từ trước)
  Widget _buildNotesGrid() {
    return Column(
      children: [
        // --- THANH TẠO GHI CHÚ GIỐNG GOOGLE KEEP ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600), // Giới hạn chiều rộng của thanh tạo ghi chú
              child: Card(
                elevation: 3, // Bóng đổ làm thanh này nổi bật hơn
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    // Chuyển sang màn hình Note Editor khi ấn vào thanh
                    context.push('/note');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Tạo ghi chú...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // Nút thêm danh sách (Checkbox)
                        IconButton(
                          icon: const Icon(Icons.check_box_outlined),
                          tooltip: 'Danh sách mới',
                          onPressed: () {
                            context.push('/note');
                          },
                        ),
                        // Nút vẽ tay
                        IconButton(
                          icon: const Icon(Icons.brush),
                          tooltip: 'Ghi chú có bản vẽ',
                          onPressed: () {
                            context.push('/note');
                          },
                        ),
                        // Nút thêm ảnh
                        IconButton(
                          icon: const Icon(Icons.image_outlined),
                          tooltip: 'Ghi chú có hình ảnh',
                          onPressed: () {
                            context.push('/note');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // --- PHẦN LƯỚI DANH SÁCH GHI CHÚ ---
        Expanded(
          child: Consumer<NotesViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.notes.isEmpty) {
                return const Center(
                  child: Text(
                    'Không có ghi chú nào.\nThêm ghi chú ở thanh bên trên!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            if (constraints.maxWidth >= 900) {
              crossAxisCount = 5;
            } else if (constraints.maxWidth >= 600) {
              crossAxisCount = 3;
            }

            return ReorderableGridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.notes.length,
              onReorder: (oldIndex, newIndex) {
                viewModel.reorderNotes(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final note = viewModel.notes[index];
                final color = note.color != null ? Color(note.color!) : Theme.of(context).cardColor;
                
                return Card(
                  key: ValueKey(note.id),
                  color: color,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      context.push('/note?id=${note.id}');
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. HIỂN THỊ HÌNH ẢNH NẾU CÓ ---
                        if (note.imagePath != null && note.imagePath!.isNotEmpty)
                          Flexible( // Dùng Flexible thay vì set cứng chiều cao 120 để tránh vỡ layout ở màn hình nhỏ
                            flex: 3,
                            child: SizedBox(
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.file(
                                  File(note.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox(height: 40, child: Center(child: Icon(Icons.broken_image))),
                                ),
                              ),
                            ),
                          ),
                        
                        // --- 2. NỘI DUNG CHÍNH (TIÊU ĐỀ, TEXT) ---
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hàng Tiêu đề và Nút Ghim
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note.title.isNotEmpty ? note.title : '',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Nút Ghim (Pin)
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                        color: note.isPinned ? Theme.of(context).colorScheme.primary : null,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        viewModel.togglePin(note.id, note.isPinned);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4), // Thu nhỏ khoảng cách lại

                                // Nội dung văn bản
                                if (note.content.isNotEmpty)
                                  Flexible( // Đổi từ Expanded thành Flexible để không bị vỡ giao diện nếu hết chỗ
                                    child: Text(
                                      note.content,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: note.imagePath != null ? 2 : 4, // Có ảnh thì thu bớt chữ
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                
                                // Hiển thị thời gian hẹn nhắc nhở
                                if (note.reminderAt != null)
                                  Flexible( // Bọc Flexible cho an toàn
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.access_time, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('dd/MM HH:mm').format(note.reminderAt!),
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // --- 3. THANH CÔNG CỤ DƯỚI CÙNG ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Nút Nhắc nhở
                              IconButton(
                                icon: const Icon(Icons.add_alert_outlined, size: 18),
                                tooltip: 'Nhắc tôi',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                onPressed: () async {
                                  // Hiển thị Popup chọn ngày
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null && context.mounted) {
                                    // Hiển thị Popup chọn giờ
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: const TimeOfDay(hour: 8, minute: 0),
                                    );
                                    if (time != null) {
                                      final reminder = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                      viewModel.setReminder(note.id, reminder);
                                    }
                                  }
                                },
                              ),
                              // Nút Đổi Màu
                              IconButton(
                                icon: const Icon(Icons.palette_outlined, size: 18),
                                tooltip: 'Đổi màu ghi chú',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                onPressed: () {
                                  // Hiển thị Popup chọn màu sắc giống như trang Note Editor
                                  _showColorPicker(context, note.id, note.color, viewModel);
                                },
                              ),
                              // Nút Thêm Hình Ảnh
                              IconButton(
                                icon: const Icon(Icons.image_outlined, size: 18),
                                tooltip: 'Thêm hình ảnh',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                onPressed: () async {
                                  // Mở hộp thoại chọn file của hệ thống máy tính
                                  FilePickerResult? result = await FilePicker.pickFiles(
                                    type: FileType.image,
                                  );
                                  if (result != null && result.files.single.path != null) {
                                    viewModel.setImage(note.id, result.files.single.path);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ), // Đóng Consumer
  ), // Đóng Expanded
  ], // Đóng mảng children của Column
  ); // Đóng Column
}

  // Bảng chọn màu sắc hiển thị từ dưới đáy màn hình lên (BottomSheet)
  void _showColorPicker(BuildContext context, int noteId, int? currentColor, NotesViewModel viewModel) {
    final List<Color> colors = [
      Colors.transparent,
      Colors.red.shade100,
      Colors.green.shade100,
      Colors.blue.shade100,
      Colors.yellow.shade100,
      Colors.purple.shade100,
      Colors.orange.shade100,
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              final isTransparent = color == Colors.transparent;
              final colorValue = isTransparent ? null : color.value;
              
              return GestureDetector(
                onTap: () {
                  viewModel.updateColor(noteId, colorValue); // Lưu màu mới xuống database
                  Navigator.pop(context); // Đóng bảng chọn màu
                },
                child: Container(
                  width: 60, height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isTransparent ? Theme.of(context).scaffoldBackgroundColor : color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: currentColor == colorValue
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
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

  // Widget hiển thị chỗ trống cho các màn hình chưa phát triển (Lời nhắc, Thùng rác, Lưu trữ...)
  Widget _buildPlaceholderScreen() {
    String title = '';
    switch (_selectedIndex) {
      case 1:
        title = 'Màn hình Lời nhắc';
        break;
      case 2:
        title = 'Màn hình Lưu trữ';
        break;
      case 3:
        title = 'Màn hình Thùng rác';
        break;
    }
    return Center(
      child: Text(
        '$title đang được xây dựng...',
        style: const TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  // Hàm hiển thị Cửa sổ Cài đặt chung (Dialog)
  void _showSettingsDialog(BuildContext context) {
    // Biến tạm để quản lý trạng thái nút gạt Thông báo ngay trên UI
    bool isNotificationEnabled = true;

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder giúp cập nhật lại UI của riêng cái cửa sổ Dialog này (như khi gạt Switch)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cài đặt'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mục 1: Cài đặt Giao diện Sáng/Tối
                    Consumer<ThemeViewModel>(
                      builder: (context, themeViewModel, child) {
                        return ListTile(
                          leading: const Icon(Icons.brightness_6),
                          title: const Text('Giao diện hiển thị'),
                          // DropdownButton để xổ ra danh sách chọn Sáng/Tối
                          trailing: DropdownButton<ThemeMode>(
                            value: themeViewModel.themeMode,
                            onChanged: (ThemeMode? newValue) {
                              if (newValue != null) {
                                themeViewModel.setThemeMode(newValue);
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: ThemeMode.light, child: Text('Sáng')),
                              DropdownMenuItem(value: ThemeMode.dark, child: Text('Tối')),
                              DropdownMenuItem(value: ThemeMode.system, child: Text('Hệ thống')),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(), // Dòng kẻ ngang phân cách
                    // Mục 2: Cài đặt Thông báo
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active),
                      title: const Text('Thông báo ứng dụng'),
                      subtitle: const Text('Bật/tắt thông báo lời nhắc nhở'),
                      value: isNotificationEnabled,
                      onChanged: (bool value) {
                        // Cập nhật giao diện của Switch ngay lập tức
                        setDialogState(() {
                          isNotificationEnabled = value;
                        });
                        // TODO: Sau này sẽ lưu biến isNotificationEnabled này vào SharedPreferences
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
