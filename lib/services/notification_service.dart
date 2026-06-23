import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:window_manager/window_manager.dart';
import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  // Singleton pattern để chỉ có 1 bản duy nhất của NotificationService chạy trong suốt vòng đời app
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await localNotifier.setup(
        appName: 'Cuong Keep',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
    } else {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          _restoreWindow();
        },
      );
    }
  }

  Future<void> _restoreWindow() async {
    try {
      await windowManager.show();
      await windowManager.restore();
      await windowManager.focus();
    } catch (e) {
      // Xử lý im lặng nếu có lỗi
    }
  }

  // Lưu trữ các thông báo để không bị Garbage Collector dọn dẹp mất sự kiện onClick
  final List<LocalNotification> _activeNotifications = [];

  Future<void> showNotification({required int id, required String title, required String body}) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      LocalNotification notification = LocalNotification(
        title: title,
        body: body,
      );
      notification.onClick = () {
        _restoreWindow();
      };
      notification.onClose = (reason) {
        _activeNotifications.remove(notification);
      };
      _activeNotifications.add(notification);
      await notification.show();
    } else {
      const NotificationDetails notificationDetails = NotificationDetails();
      await _flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: id.toString(),
      );
    }
  }
}
