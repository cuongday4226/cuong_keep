import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/database.dart';
import 'view_models/notes_view_model.dart';
import 'routes/app_router.dart';

// Đây là hàm main() - Điểm xuất phát của toàn bộ ứng dụng Flutter. Ứng dụng luôn chạy từ hàm này đầu tiên.
void main() {
  // Hàm này đảm bảo các công cụ hỗ trợ lõi của Flutter được bật lên và sẵn sàng làm việc trước khi giao diện bắt đầu chạy
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Cơ sở dữ liệu SQLite thông qua lớp AppDatabase (được định nghĩa trong thư mục models)
  final db = AppDatabase();
  
  // runApp() là lệnh phát nổ khởi động giao diện ứng dụng.
  runApp(
    // Dùng MultiProvider để bọc ứng dụng lại. 
    // Việc này giống như tạo 1 cái loa thông báo khổng lồ bao trùm cả app. Bất kỳ màn hình nào nằm bên trong đều có thể nghe được thông báo.
    MultiProvider(
      providers: [
        // ChangeNotifierProvider khởi tạo ViewModel. Bất kỳ khi nào NotesViewModel có thay đổi dữ liệu,
        // nó sẽ phát thông báo để các widget đăng ký nghe (Consumer) tự cập nhật giao diện.
        ChangeNotifierProvider(
          create: (_) => NotesViewModel(db),
        ),
      ],
      // MyApp là phần giao diện gốc rễ của app
      child: const MyApp(),
    ),
  );
}

// MyApp: Đây là widget ngoài cùng, chứa các cài đặt cơ bản như Theme, Màu sắc và Định tuyến
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp.router: Là một chuẩn ứng dụng Material Design, dùng .router để hỗ trợ sử dụng hệ thống GoRouter
    return MaterialApp.router(
      title: 'Cuong Keep', // Tên ứng dụng
      
      // Cấu hình Theme (Giao diện màu sáng)
      theme: ThemeData(
        // ColorScheme.fromSeed giúp tạo ra toàn bộ bảng màu chuẩn dựa trên một màu chủ đạo (seedColor), ở đây là xanh mòng két (teal)
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true, // Kích hoạt bộ quy chuẩn thiết kế mới nhất của Google (Material Design 3)
      ),
      
      // Cấu hình Theme (Giao diện chế độ tối - Dark Mode)
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      
      // ThemeMode.system: Tự động đổi sáng/tối theo cài đặt của hệ điều hành Windows
      themeMode: ThemeMode.system,
      
      // routerConfig: Tiêm cấu hình các đường dẫn màn hình (từ file app_router.dart) vào ứng dụng
      routerConfig: appRouter,
    );
  }
}
