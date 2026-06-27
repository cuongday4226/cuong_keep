import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:go_router/go_router.dart';
import '../view_models/notes_view_model.dart';
import '../view_models/theme_view_model.dart';
import '../widgets/edit_labels_dialog.dart';
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
        selectedIndex: _getDrawerIndex(notesVM),
        onDestinationSelected: (int index) => _onDestinationSelected(index, notesVM),
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
          if (notesVM.allTags.isNotEmpty) ...[
            const Divider(indent: 28, endIndent: 28),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
              child: Text(
                'Nhãn',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            ...notesVM.allTags.map((tag) => NavigationDrawerDestination(
              icon: const Icon(Icons.label_outline),
              selectedIcon: const Icon(Icons.label),
              label: Text(tag),
            )),
          ],
          const NavigationDrawerDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: Text('Chỉnh sửa nhãn'),
          ),
          const Divider(indent: 28, endIndent: 28),
          const NavigationDrawerDestination(
            icon: Icon(Icons.archive_outlined),
            selectedIcon: Icon(Icons.archive),
            label: Text('Lưu trữ'),
          ),
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
            if (notesVM.currentFilter != NoteFilter.trash)
              IconButton(
                icon: const Icon(Icons.push_pin_outlined),
                tooltip: 'Ghim / Bỏ ghim',
                onPressed: () => notesVM.togglePinSelectedNotes(),
              ),
            if (notesVM.currentFilter == NoteFilter.trash)
              IconButton(
                icon: const Icon(Icons.restore),
                tooltip: 'Khôi phục',
                onPressed: () => notesVM.restoreSelectedNotes(),
              ),
            if (notesVM.currentFilter != NoteFilter.archive && notesVM.currentFilter != NoteFilter.trash)
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                tooltip: 'Lưu trữ',
                onPressed: () => notesVM.toggleArchiveSelectedNotes(),
              ),
            if (notesVM.currentFilter == NoteFilter.archive)
              IconButton(
                icon: const Icon(Icons.unarchive_outlined),
                tooltip: 'Bỏ lưu trữ',
                onPressed: () => notesVM.toggleArchiveSelectedNotes(),
              ),
            if (notesVM.currentFilter != NoteFilter.trash)
              IconButton(
                icon: const Icon(Icons.label_outline),
                tooltip: 'Gắn nhãn',
                onPressed: () => _showTagsDialogForSelection(notesVM),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: notesVM.currentFilter == NoteFilter.trash ? 'Xóa vĩnh viễn' : 'Xóa',
              onPressed: () {
                if (notesVM.currentFilter == NoteFilter.trash) {
                  notesVM.permanentlyDeleteSelectedNotes();
                } else {
                  notesVM.moveSelectedNotesToTrash();
                }
              },
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
      // Hiển thị giao diện chính dựa trên bộ lọc
      body: _buildNotesGrid(notesVM),
    );
  }

  int _getDrawerIndex(NotesViewModel notesVM) {
    if (notesVM.currentFilter == NoteFilter.notes) return 0;
    if (notesVM.currentFilter == NoteFilter.reminders) return 1;
    
    final tags = notesVM.allTags;
    if (notesVM.currentFilter == NoteFilter.label) {
      int tagIndex = tags.indexOf(notesVM.currentLabel ?? '');
      if (tagIndex != -1) return 2 + tagIndex;
    }
    
    if (notesVM.currentFilter == NoteFilter.archive) return 2 + tags.length + 1;
    if (notesVM.currentFilter == NoteFilter.trash) return 2 + tags.length + 2;
    
    return 0;
  }

  void _onDestinationSelected(int index, NotesViewModel notesVM) {
    final tags = notesVM.allTags;
    if (index == 0) {
      notesVM.setFilter(NoteFilter.notes);
    } else if (index == 1) {
      notesVM.setFilter(NoteFilter.reminders);
    } else if (index >= 2 && index < 2 + tags.length) {
      notesVM.setFilter(NoteFilter.label, label: tags[index - 2]);
    } else if (index == 2 + tags.length) {
      Navigator.pop(context); // Tự động đóng Drawer
      showDialog(context: context, builder: (_) => const EditLabelsDialog());
      return; // Không đổi filter
    } else if (index == 2 + tags.length + 1) {
      notesVM.setFilter(NoteFilter.archive);
    } else if (index == 2 + tags.length + 2) {
      notesVM.setFilter(NoteFilter.trash);
    }
    Navigator.pop(context); // Tự động đóng Drawer
  }

  // Widget riêng dành cho giao diện chính của phần Ghi chú
  Widget _buildNotesGrid(NotesViewModel notesVM) {
    // Chỉ cho phép tạo ghi chú mới ở màn hình Chính và màn hình Nhãn
    final canCreateNote = notesVM.currentFilter == NoteFilter.notes || notesVM.currentFilter == NoteFilter.label;

    return Column(
      children: [
        if (canCreateNote)
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
        if (notesVM.currentFilter == NoteFilter.trash)
          _buildEmptyTrashButton(notesVM),
        // --- PHẦN LƯỚI DANH SÁCH GHI CHÚ ---
        Expanded(
          child: Consumer<NotesViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.notes.isEmpty) {
                String emptyMsg = 'Không có ghi chú nào.';
                if (viewModel.currentFilter == NoteFilter.notes) emptyMsg = 'Ghi chú bạn thêm sẽ xuất hiện ở đây.';
                if (viewModel.currentFilter == NoteFilter.reminders) emptyMsg = 'Ghi chú có lời nhắc sẽ xuất hiện ở đây.';
                if (viewModel.currentFilter == NoteFilter.archive) emptyMsg = 'Ghi chú được lưu trữ sẽ xuất hiện ở đây.';
                if (viewModel.currentFilter == NoteFilter.trash) emptyMsg = 'Thùng rác trống.';
                
                return Center(
                  child: Text(
                    emptyMsg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16),
                                          onTap: () {
                                            // Xóa lời nhắc khi bấm vào thẻ
                                            viewModel.setReminder(note.id, null);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.access_time, size: 13),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('dd/MM HH:mm').format(note.reminderAt!),
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(Icons.close, size: 13, color: Colors.grey),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  
                                  // Hiển thị nhãn
                                  if (note.tags != null && note.tags!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: note.tags!.map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
                                          ),
                                          child: Text(tag, style: const TextStyle(fontSize: 11)),
                                        )).toList(),
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
                      findChildIndexCallback: (Key key) {
                        if (key is ValueKey<String>) {
                          final String val = key.value;
                          if (val.startsWith('pinned_')) {
                            final id = int.tryParse(val.replaceFirst('pinned_', ''));
                            if (id != null) {
                              final index = viewModel.pinnedNotes.indexWhere((n) => n.id == id);
                              if (index >= 0) return index;
                            }
                          }
                        }
                        return null;
                      },
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex < newIndex) newIndex -= 1;
                        viewModel.reorderPinnedNotes(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final note = viewModel.pinnedNotes[index];
                        return ReorderableDragStartListener(
                          key: ValueKey('pinned_${note.id}'),
                          index: index,
                          enabled: !viewModel.isSelectionMode,
                          child: RepaintBoundary(child: buildNoteCard(note)),
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
                    sliver: SliverToBoxAdapter(
                      child: ReorderableBuilder(
                        enableDraggable: !viewModel.isSelectionMode,
                        longPressDelay: Duration.zero,
                        onReorder: (List<Note> Function(List<Note>) reorderedListFunction) {
                          viewModel.reorderPinnedNotesWithFunction(reorderedListFunction);
                        },
                        children: List.generate(viewModel.pinnedNotes.length, (index) {
                          final note = viewModel.pinnedNotes[index];
                          return Container(
                            key: ValueKey('pinned_${note.id}'),
                            child: RepaintBoundary(child: buildNoteCard(note)),
                          );
                        }),
                        builder: (children) {
                          return GridView(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            children: children,
                          );
                        },
                      ),
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
                      findChildIndexCallback: (Key key) {
                        if (key is ValueKey<String>) {
                          final String val = key.value;
                          if (val.startsWith('unpinned_')) {
                            final id = int.tryParse(val.replaceFirst('unpinned_', ''));
                            if (id != null) {
                              final index = viewModel.unpinnedNotes.indexWhere((n) => n.id == id);
                              if (index >= 0) return index;
                            }
                          }
                        }
                        return null;
                      },
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex < newIndex) newIndex -= 1;
                        viewModel.reorderUnpinnedNotes(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final note = viewModel.unpinnedNotes[index];
                        return ReorderableDragStartListener(
                          key: ValueKey('unpinned_${note.id}'),
                          index: index,
                          enabled: !viewModel.isSelectionMode,
                          child: RepaintBoundary(child: buildNoteCard(note)),
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
                    sliver: SliverToBoxAdapter(
                      child: ReorderableBuilder(
                        enableDraggable: !viewModel.isSelectionMode,
                        longPressDelay: Duration.zero,
                        onReorder: (List<Note> Function(List<Note>) reorderedListFunction) {
                          viewModel.reorderUnpinnedNotesWithFunction(reorderedListFunction);
                        },
                        children: List.generate(viewModel.unpinnedNotes.length, (index) {
                          final note = viewModel.unpinnedNotes[index];
                          return Container(
                            key: ValueKey('unpinned_${note.id}'),
                            child: RepaintBoundary(child: buildNoteCard(note)),
                          );
                        }),
                        builder: (children) {
                          return GridView(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            children: children,
                          );
                        },
                      ),
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

  // Nút Dọn sạch thùng rác (Chỉ hiển thị ở màn hình Thùng rác)
  Widget _buildEmptyTrashButton(NotesViewModel notesVM) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: notesVM.notes.isEmpty ? null : () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Dọn sạch thùng rác?'),
              content: const Text('Tất cả ghi chú trong thùng rác sẽ bị xóa vĩnh viễn và không thể khôi phục.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    notesVM.emptyTrash();
                  },
                  child: const Text('Dọn sạch', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.delete_forever),
        label: const Text('Dọn sạch thùng rác'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
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
                        Navigator.pop(context); // Đóng dialog Settings
                        // Dùng context của HomeScreen (không phải context của dialog đã đóng)
                        BackupService.backupData(this.context);
                      },
                    ),
                    // Mục 4: Phục hồi dữ liệu
                    ListTile(
                      leading: const Icon(Icons.cloud_download_outlined),
                      title: const Text('Nhập dữ liệu'),
                      subtitle: const Text('Khôi phục từ bản sao lưu'),
                      onTap: () {
                        Navigator.pop(context); // Đóng dialog Settings
                        // Dùng context của HomeScreen (không phải context của dialog đã đóng)
                        BackupService.restoreData(this.context);
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

  void _showTagsDialogForSelection(NotesViewModel viewModel) {
    final allTags = viewModel.allTags.toList();
    final TextEditingController newTagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Gắn nhãn'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ô nhập nhãn mới
                    TextField(
                      controller: newTagController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tên nhãn mới...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final text = newTagController.text.trim();
                            if (text.isNotEmpty) {
                              setDialogState(() {
                                if (!allTags.contains(text)) {
                                  allTags.add(text);
                                  viewModel.addGlobalLabel(text);
                                }
                                viewModel.toggleTagForSelectedNotes(text, true);
                                newTagController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      onSubmitted: (text) {
                        text = text.trim();
                        if (text.isNotEmpty) {
                          setDialogState(() {
                            if (!allTags.contains(text)) {
                              allTags.add(text);
                              viewModel.addGlobalLabel(text);
                            }
                            viewModel.toggleTagForSelectedNotes(text, true);
                            newTagController.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Danh sách các nhãn
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allTags.length,
                        itemBuilder: (context, index) {
                          final tag = allTags[index];
                          final state = viewModel.getTagStateForSelectedNotes(tag);
                          
                          return CheckboxListTile(
                            title: Text(tag),
                            value: state,
                            tristate: true,
                            onChanged: (bool? newValue) {
                              setDialogState(() {
                                viewModel.toggleTagForSelectedNotes(tag, state);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Xong'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
