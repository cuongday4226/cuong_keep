import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern để chỉ có 1 bản duy nhất của NotificationService chạy trong suốt vòng đời app
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Cấu hình khởi tạo (Android, iOS, macOS, Windows...)
    // Đối với Windows và Linux, cấu hình mặc định (tạm thời để rỗng hoặc setup theo doc)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Windows cần cấu hình các thông số cơ bản
    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
          appName: 'Cuong Keep',
          appUserModelId: 'com.cuong.keep',
          guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      windows: initializationSettingsWindows,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<void> showNotification({required int id, required String title, required String body}) async {
    // Windows Notification details
    // Mặc định flutter_local_notifications sẽ dùng toast của hệ điều hành
    const NotificationDetails notificationDetails = NotificationDetails();

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
