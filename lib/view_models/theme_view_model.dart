import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ThemeViewModel: Lớp quản lý trạng thái giao diện (Sáng/Tối/Hệ thống)
class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isListView = false;

  ThemeMode get themeMode => _themeMode;
  bool get isListView => _isListView;

  ThemeViewModel() {
    _loadTheme();
  }

  // Tải cài đặt giao diện đã lưu từ lần trước
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    
    _isListView = prefs.getBool('is_list_view') ?? false;
    
    notifyListeners();
  }

  // Đổi giao diện và lưu lại cài đặt
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  void toggleViewMode() async {
    _isListView = !_isListView;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_list_view', _isListView);
  }

  void toggleThemeMode() async {
    ThemeMode newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}
