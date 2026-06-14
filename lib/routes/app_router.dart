import 'package:go_router/go_router.dart';
import '../views/home_screen.dart';
import '../views/note_editor_screen.dart';

// appRouter: Là biến chứa toàn bộ cấu hình điều hướng (chuyển màn hình) của ứng dụng
// GoRouter là một thư viện giúp cho việc chuyển màn hình trong Flutter trở nên gọn gàng và giống với việc chuyển URL trên web.
final appRouter = GoRouter(
  // initialLocation: Màn hình đầu tiên sẽ hiển thị khi mở app. '/' thường tượng trưng cho trang chủ (Home)
  initialLocation: '/',
  
  // routes: Danh sách các màn hình (đường dẫn) có trong ứng dụng
  routes: [
    // Định nghĩa màn hình Trang chủ
    GoRoute(
      path: '/', // Đường dẫn gốc
      // builder: Trả về giao diện (Widget) tương ứng với đường dẫn này, ở đây là HomeScreen
      builder: (context, state) => const HomeScreen(),
    ),
    
    // Định nghĩa màn hình Chỉnh sửa / Thêm mới ghi chú
    GoRoute(
      path: '/note', // Đường dẫn /note
      builder: (context, state) {
        // state.uri.queryParameters giúp ta lấy các tham số truyền vào từ URL.
        // Ví dụ nếu URL là '/note?id=5', ta sẽ lấy được số 5 để biết đang muốn sửa ghi chú số 5
        final noteId = state.uri.queryParameters['id'];
        
        return NoteEditorScreen(
          // Nếu có noteId (người dùng bấm vào ghi chú cũ để sửa), ta truyền id đó vào. 
          // Ngược lại (người dùng bấm nút Thêm mới), ta truyền null.
          noteId: noteId != null ? int.tryParse(noteId) : null,
        );
      },
    ),
  ],
);
