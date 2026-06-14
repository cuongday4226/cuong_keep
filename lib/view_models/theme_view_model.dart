import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ThemeViewModel: Lớp quản lý trạng thái giao diện (Sáng/Tối/Hệ thống)
class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeViewModel() {
    _loadTheme();
  }

  // Tải cài đặt giao diện đã lưu từ lần trước
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode') ?? 'system';
    
    switch (themeString) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  // Đổi giao diện và lưu lại cài đặt
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String themeString = 'system';
    if (mode == ThemeMode.light) themeString = 'light';
    if (mode == ThemeMode.dark) themeString = 'dark';
    
    await prefs.setString('themeMode', themeString);
  }
}
