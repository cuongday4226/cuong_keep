import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../view_models/notes_view_model.dart';
import '../view_models/theme_view_model.dart';
import '../utils/color_utils.dart';
import '../utils/string_utils.dart';
import '../models/database.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';

// Đổi từ StatelessWidget sang StatefulWidget để có thể quản lý trạng thái của Navigation Drawer
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Biến lưu trữ mục nào đang được chọn trong ngăn kéo (0 = Ghi chú, mặc định)
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesVM = context.watch<NotesViewModel>();
    final isSelectionMode = notesVM.isSelectionMode;

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
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Cuong Keep',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: Text('Ghi chú'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: Text('Lời nhắc'),
          ),
          const Divider(indent: 28, endIndent: 28),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Nhãn',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          // Có thể thêm các mục Nhãn ở đây sau này
          const Divider(indent: 28, endIndent: 28),
          const NavigationDrawerDestination(
            icon: Icon(Icons.delete_outline),
            selectedIcon: Icon(Icons.delete),
            label: Text('Thùng rác'),
          ),
        ],
      ),
      appBar: isSelectionMode 
      ? AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => notesVM.clearSelection(),
          ),
          title: Text(
            'Đã chọn ${notesVM.selectedNoteIds.length} mục',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.push_pin_outlined),
              tooltip: 'Ghim / Bỏ ghim',
              onPressed: () => notesVM.togglePinSelectedNotes(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa các mục đã chọn',
              onPressed: () => notesVM.deleteSelectedNotes(),
            ),
          ],
        )
      : AppBar(
        // Tiêu đề bây giờ là một thanh Tìm kiếm (Search bar)
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            // Màu nền của thanh tìm kiếm (hơi xám)
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (text) {
              context.read<NotesViewModel>().setSearchQuery(text); // Gửi chữ về ViewModel để lọc
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  if (value.text.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<NotesViewModel>().setSearchQuery('');
                    },
                  );
                },
              ),
              border: InputBorder.none, // Xóa gạch chân mặc định của TextField
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Căn giữa chữ
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
          Consumer<ThemeViewModel>(
            builder: (context, theme, child) {
              return IconButton(
                icon: Icon(theme.isListView ? Icons.grid_view : Icons.view_agenda_outlined),
                tooltip: theme.isListView ? 'Chế độ xem lưới' : 'Chế độ xem danh sách',
                onPressed: () {
                  theme.toggleViewMode();
                },
              );
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
                            context.push('/note?action=check');
                          },
                        ),
                        // Nút vẽ tay
                        IconButton(
                          icon: const Icon(Icons.brush),
                          tooltip: 'Ghi chú có bản vẽ',
                          onPressed: () {
                            context.push('/note?action=draw');
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
            final isListView = context.watch<ThemeViewModel>().isListView;

            // Hàm phụ để render ảnh
            Widget buildImageGallery(List<String> imagePaths) {
              Widget buildSingleImage(String path, {double? height}) {
                return SizedBox(
                  width: double.infinity,
                  height: height,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) =>
                        SizedBox(height: height ?? 100, child: const Center(child: Icon(Icons.broken_image))),
                  ),
                );
              }

              if (imagePaths.length == 1) {
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: isListView ? 300 : 120),
                  child: buildSingleImage(imagePaths[0]),
                );
              } else if (imagePaths.length == 2) {
                double h = isListView ? 150 : 100;
                return SizedBox(
                  height: h,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: buildSingleImage(imagePaths[0], height: h)),
                      const SizedBox(width: 2),
                      Expanded(child: buildSingleImage(imagePaths[1], height: h)),
                    ],
                  ),
                );
              } else {
                double topH = isListView ? 150 : 80;
                double botH = isListView ? 100 : 60;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildSingleImage(imagePaths[0], height: topH),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: botH,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: buildSingleImage(imagePaths[1], height: botH)),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Stack(
                              fit: StackFit.passthrough,
                              children: [
                                buildSingleImage(imagePaths[2], height: botH),
                                if (imagePaths.length > 3)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black54,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '+${imagePaths.length - 3}',
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            }

            // Widget tạo ra 1 thẻ Ghi chú hoàn chỉnh, tự động co giãn theo nội dung
            Widget buildNoteCard(Note note) {
              final color = ColorUtils.getAdaptiveColor(context, note.color);
              final isSelected = viewModel.selectedNoteIds.contains(note.id);

              return GestureDetector(
                key: ValueKey(note.id),
                onSecondaryTap: () {
                  // Click chuột phải luôn bật/tắt chọn
                  viewModel.toggleSelection(note.id);
                },
                child: Card(
                  color: color,
                  elevation: isSelected ? 4 : 1,
                  margin: EdgeInsets.only(bottom: isListView ? 12 : 0), // Nếu là List thì thêm khoảng cách dưới
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant, 
                      width: isSelected ? 2 : 1
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onLongPress: () {
                      // Nhấn giữ bật/tắt chọn
                      viewModel.toggleSelection(note.id);
                    },
                    onTap: () {
                      if (viewModel.isSelectionMode) {
                        viewModel.toggleSelection(note.id);
                      } else {
                        context.push('/note?id=${note.id}');
                      }
                    },
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min, // QUAN TRỌNG: Ôm sát nội dung, không bị kéo dãn cứng ngắc
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- 1. HIỂN THỊ HÌNH ẢNH NẾU CÓ ---
                            if (note.imagePaths != null && note.imagePaths!.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: buildImageGallery(note.imagePaths!),
                              ),

                      // --- 2. NỘI DUNG CHÍNH (TIÊU ĐỀ, TEXT) ---
                      // Dùng Flexible kết hợp với ClipRect để ngăn chữ tràn ra ngoài giới hạn của thẻ (gây lỗi Overflow)
                      Flexible(
                        fit: isListView ? FlexFit.loose : FlexFit.tight,
                        child: ClipRect(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(), // Không cho cuộn, chỉ dùng để cắt phần thừa
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hàng Tiêu đề và chừa khoảng trống cho Nút Ghim
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
                                      const SizedBox(width: 32), // Chừa không gian cho nút ghim nổi lên trên
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Nội dung văn bản hoặc danh sách
                                  if (note.isChecklist && note.checklistItems != null)
                                    ...() {
                                      // Sao chép và sắp xếp danh sách: Chưa check lên trên, đã check xuống dưới, cùng loại thì xếp ABC
                                      final displayItems = List<ChecklistItem>.from(note.checklistItems!);
                                      displayItems.sort((a, b) {
                                        if (a.isCompleted == b.isCompleted) {
                                          return StringUtils.removeDiacritics(a.text.toLowerCase())
                                              .compareTo(StringUtils.removeDiacritics(b.text.toLowerCase()));
                                        }
                                        return a.isCompleted ? 1 : -1;
                                      });

                                      return displayItems.take(5).map((item) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(right: 8, bottom: 4),
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: Icon(
                                                    item.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                                                    size: 16,
                                                    color: item.isCompleted ? Colors.grey : Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                  onPressed: () {
                                                    // Nếu đang đa chọn thì không cho ấn nút checklist
                                                    if (viewModel.isSelectionMode) {
                                                      viewModel.toggleSelection(note.id);
                                                      return;
                                                    }
                                                    // Tìm vị trí của mục này và đảo ngược trạng thái
                                                    final updatedItems = List<ChecklistItem>.from(note.checklistItems!);
                                                    final idx = updatedItems.indexWhere((e) => e.id == item.id);
                                                    if (idx != -1) {
                                                      updatedItems[idx].isCompleted = !updatedItems[idx].isCompleted;
                                                      
                                                      // Sắp xếp lại trước khi lưu
                                                      updatedItems.sort((a, b) {
                                                        if (a.isCompleted == b.isCompleted) {
                                                          return StringUtils.removeDiacritics(a.text.toLowerCase())
                                                              .compareTo(StringUtils.removeDiacritics(b.text.toLowerCase()));
                                                        }
                                                        return a.isCompleted ? 1 : -1;
                                                      });

                                                      viewModel.updateNote(
                                                        note.id, note.title, note.content, note.color, note.imagePaths, true, updatedItems
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  item.text,
                                                  style: TextStyle(
                                                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                                    color: item.isCompleted ? Colors.grey : null,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      });
                                    }(),
                                  if (!note.isChecklist && note.content.isNotEmpty)
                                    Text(
                                      note.content,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: (note.imagePaths != null && note.imagePaths!.isNotEmpty) ? 3 : 15, // Tăng maxLines vì đã có Flexible cắt bớt
                                      overflow: TextOverflow.fade, // Đổi sang fade để mờ đi nếu bị cắt
                                    ),

                                  // Hiển thị thời gian hẹn nhắc nhở
                                  if (note.reminderAt != null)
                                    Container(
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // --- 3. THANH CÔNG CỤ DƯỚI CÙNG ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_alert_outlined, size: 18),
                              tooltip: 'Nhắc tôi',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 1)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null && context.mounted) {
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
                            IconButton(
                              icon: const Icon(Icons.palette_outlined, size: 18),
                              tooltip: 'Đổi màu ghi chú',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              onPressed: () {
                                _showColorPicker(context, note.id, note.color, viewModel);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.image_outlined, size: 18),
                              tooltip: 'Thêm hình ảnh',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image);
                                if (result != null && result.files.single.path != null) {
                                  viewModel.addImage(note.id, result.files.single.path!);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  // Nút ghim luôn cố định ở góc trên cùng bên phải
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: note.imagePaths?.isNotEmpty == true ? Colors.black.withOpacity(0.3) : Colors.transparent,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        icon: Icon(
                          note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          color: note.isPinned 
                              ? Theme.of(context).colorScheme.primary 
                              : (note.imagePaths?.isNotEmpty == true ? Colors.white : null),
                          size: 20,
                        ),
                        onPressed: () {
                          viewModel.togglePin(note.id, note.isPinned);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

            Widget buildSectionHeader(String title) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            final slivers = <Widget>[];

            if (viewModel.pinnedNotes.isNotEmpty) {
              slivers.add(buildSectionHeader('ĐƯỢC GHIM'));
              if (isListView) {
                slivers.add(
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverReorderableList(
                      itemCount: viewModel.pinnedNotes.length,
                      onReorder: (oldIndex, newIndex) {
                        viewModel.reorderPinnedNotes(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final note = viewModel.pinnedNotes[index];
                        return ReorderableDragStartListener(
                          key: ValueKey('pinned_${note.id}'),
                          index: index,
                          child: buildNoteCard(note),
                        );
                      },
                    ),
                  ),
                );
              } else {
                int crossAxisCount = (constraints.maxWidth / 280).ceil();
                if (crossAxisCount < 2) crossAxisCount = 2;
                slivers.add(
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: ReorderableSliverGridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      dragStartDelay: Duration.zero,
                      onReorder: (oldIndex, newIndex) {
                        viewModel.reorderPinnedNotes(oldIndex, newIndex);
                      },
                      children: List.generate(viewModel.pinnedNotes.length, (index) {
                        final note = viewModel.pinnedNotes[index];
                        return SizedBox(
                          key: ValueKey('pinned_${note.id}'),
                          child: buildNoteCard(note),
                        );
                      }),
                    ),
                  ),
                );
              }
            }

            if (viewModel.unpinnedNotes.isNotEmpty) {
              if (viewModel.pinnedNotes.isNotEmpty) {
                slivers.add(buildSectionHeader('KHÁC'));
              }
              if (isListView) {
                slivers.add(
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverReorderableList(
                      itemCount: viewModel.unpinnedNotes.length,
                      onReorder: (oldIndex, newIndex) {
                        viewModel.reorderUnpinnedNotes(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final note = viewModel.unpinnedNotes[index];
                        return ReorderableDragStartListener(
                          key: ValueKey('unpinned_${note.id}'),
                          index: index,
                          child: buildNoteCard(note),
                        );
                      },
                    ),
                  ),
                );
              } else {
                int crossAxisCount = (constraints.maxWidth / 280).ceil();
                if (crossAxisCount < 2) crossAxisCount = 2;
                slivers.add(
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: ReorderableSliverGridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      dragStartDelay: Duration.zero,
                      onReorder: (oldIndex, newIndex) {
                        viewModel.reorderUnpinnedNotes(oldIndex, newIndex);
                      },
                      children: List.generate(viewModel.unpinnedNotes.length, (index) {
                        final note = viewModel.unpinnedNotes[index];
                        return SizedBox(
                          key: ValueKey('unpinned_${note.id}'),
                          child: buildNoteCard(note),
                        );
                      }),
                    ),
                  ),
                );
              }
            }

            Widget scrollView = CustomScrollView(
              slivers: slivers.isEmpty 
                  ? [const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Chưa có ghi chú nào'))))] 
                  : slivers,
            );

            if (isListView) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: scrollView,
                ),
              );
            } else {
              return scrollView;
            }
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
                    color: isTransparent ? Theme.of(context).scaffoldBackgroundColor : ColorUtils.getAdaptiveColor(context, colorValue),
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
                        setDialogState(() {
                          isNotificationEnabled = value;
                        });
                        // Có thể lưu trạng thái này vào SharedPreferences sau này
                      },
                    ),
                    const Divider(),
                    // Mục 3: Sao lưu dữ liệu
                    ListTile(
                      leading: const Icon(Icons.cloud_upload_outlined),
                      title: const Text('Sao lưu dữ liệu'),
                      subtitle: const Text('Xuất ghi chú và hình ảnh'),
                      onTap: () {
                        Navigator.pop(context);
                        BackupService.backupData(context);
                      },
                    ),
                    // Mục 4: Phục hồi dữ liệu
                    ListTile(
                      leading: const Icon(Icons.cloud_download_outlined),
                      title: const Text('Nhập dữ liệu'),
                      subtitle: const Text('Khôi phục từ tệp ZIP'),
                      onTap: () {
                        Navigator.pop(context);
                        BackupService.restoreData(context);
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
