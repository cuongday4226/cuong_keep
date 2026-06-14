import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart'; // Thay thế thư viện MasonryGridView
import 'package:go_router/go_router.dart';
import '../view_models/notes_view_model.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi chú'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<NotesViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.notes.isEmpty) {
            return const Center(
              child: Text(
                'Không có ghi chú nào.\nHãy tạo một ghi chú mới!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // LayoutBuilder giúp ta lấy được thông tin chiều rộng và chiều cao của không gian trống hiện tại.
          // Đây là chìa khóa để làm Responsive cho ứng dụng trên PC.
          return LayoutBuilder(
            builder: (context, constraints) {
              // --- 1. TÍNH TOÁN RESPONSIVE (Số lượng cột linh hoạt) ---
              int crossAxisCount = 2; // Mặc định dành cho màn hình nhỏ (Mobile)
              if (constraints.maxWidth >= 900) {
                crossAxisCount = 5; // Màn hình rộng (PC / Desktop lớn)
              } else if (constraints.maxWidth >= 600) {
                crossAxisCount = 3; // Màn hình vừa (Tablet / Cửa sổ thu nhỏ)
              }

              // --- 2. GIAO DIỆN LƯỚI KÉO THẢ (Drag & Drop) ---
              // Sử dụng ReorderableGridView.builder từ thư viện reorderable_grid_view
              return ReorderableGridView.builder(
                // Cấu hình chia cột
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount, // Số lượng cột linh động theo Responsive
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  // Tỉ lệ cạnh (Rộng / Cao). 
                  // Do hệ thống kéo thả mặc định hoạt động tốt nhất trên lưới chuẩn nên ta để tỷ lệ 1:1 (Ô vuông).
                  childAspectRatio: 1.0, 
                ),
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.notes.length,
                
                // Bắt sự kiện khi người dùng kéo thả xong
                onReorder: (oldIndex, newIndex) {
                  // Chuyển giao việc cập nhật và lưu dữ liệu cho ViewModel
                  viewModel.reorderNotes(oldIndex, newIndex);
                },
                
                itemBuilder: (context, index) {
                  final note = viewModel.notes[index];
                  final color = note.color != null ? Color(note.color!) : Theme.of(context).cardColor;
                  
                  // LƯU Ý QUAN TRỌNG: Mọi widget con của ReorderableGridView BẮT BUỘC PHẢI CÓ THUỘC TÍNH "key".
                  // Thuộc tính này giúp hệ thống Flutter nhận diện được đúng thẻ nào đang bị kéo đi đâu.
                  return Card(
                    key: ValueKey(note.id), // <-- Bắt buộc để Kéo Thả hoạt động đúng
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
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.title.isNotEmpty) ...[
                              Text(
                                note.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (note.content.isNotEmpty)
                              // Dùng Expanded để đẩy phần ngày tháng xuống dưới cùng của ô vuông
                              Expanded(
                                child: Text(
                                  note.content,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 8,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            else
                              const Spacer(), // Nếu không có nội dung thì cũng đẩy xuống để ngày tháng nằm ở đáy ô
                            
                            const SizedBox(height: 12),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(note.modifiedAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/note');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
