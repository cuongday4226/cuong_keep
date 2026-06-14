import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'dart:io';

import 'models/database.dart';
import 'view_models/notes_view_model.dart';
import 'view_models/theme_view_model.dart';
import 'routes/app_router.dart';
import 'services/notification_service.dart';

void main() async {
  // Hàm này đảm bảo các công cụ hỗ trợ lõi của Flutter được bật lên và sẵn sàng làm việc trước khi giao diện bắt đầu chạy
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo dịch vụ thông báo
  await NotificationService().init();
  
  // KHỞI TẠO CỬA SỔ VÀ KHAY HỆ THỐNG
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1000, 700),
    center: true,
    title: 'Cuong Keep',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    // Bật tính năng chặn phím X để ứng dụng không bị tắt hẳn, mà sẽ ẩn xuống khay hệ thống (System Tray)
    await windowManager.setPreventClose(true);
  });

  // Khởi tạo Icon dưới System Tray
  if (Platform.isWindows) {
    await trayManager.setIcon('assets/images/app_icon.ico');
    Menu menu = Menu(
      items: [
        MenuItem(key: 'show_app', label: 'Mở ứng dụng'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Thoát hoàn toàn'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  // Khởi tạo Cơ sở dữ liệu SQLite thông qua lớp AppDatabase (được định nghĩa trong thư mục models)
  final db = AppDatabase();
  
  // runApp() là lệnh phát nổ khởi động giao diện ứng dụng.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesViewModel(db)),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

// MyApp: Đây là widget ngoài cùng, nay được nâng cấp thành StatefulWidget để lắng nghe sự kiện của Window và Tray
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// Mixin TrayListener và WindowListener để nghe các cú click chuột vào System Tray và nút X
class _MyAppState extends State<MyApp> with TrayListener, WindowListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  // Khi click đúp chuột trái vào icon dưới thanh taskbar -> Mở app lên
  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  // Khi click chuột phải vào icon dưới thanh taskbar -> Hiện menu (Mở app / Thoát)
  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  // Khi bấm vào 1 mục trong menu chuột phải
  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_app') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy(); // Lệnh này sẽ giết hẳn tiến trình app (Thoát hoàn toàn)
    }
  }

  // Khi người dùng bấm dấu X đỏ trên cửa sổ Windows
  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      windowManager.hide(); // Ẩn cửa sổ đi thay vì đóng app
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dùng Consumer để lắng nghe sự thay đổi của ThemeViewModel
    return Consumer<ThemeViewModel>(
      builder: (context, themeViewModel, child) {
        return MaterialApp.router(
          title: 'Cuong Keep',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeViewModel.themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
