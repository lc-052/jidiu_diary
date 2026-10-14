import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ThemeController extends ChangeNotifier {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
      ThemeMode _themeMode = ThemeMode.system;
      ThemeMode get themeMode => _themeMode;
      void setThemeMode(ThemeMode mode) {
        _themeMode = mode;
        notifyListeners();
        saveTheme(mode);
      }
  Future<void> saveTheme(ThemeMode mode) async {
    await _prefs.setString('theme_mode', mode.name);
  }
  Future<void> loadTheme() async {
    // ① 从本地读取保存的主题
    final String? savedMode = await _prefs.getString('theme_mode');

    // ② 将字符串转换为 ThemeMode
    final mode = ThemeMode.values
        .where((item) => item.name == savedMode)
        .firstOrNull;

    // ③ 找到对应主题后，更新状态
    if (mode != null) {
      _themeMode = mode;
      notifyListeners();
    }
  }
}