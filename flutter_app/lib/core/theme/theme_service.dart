import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'theme_storage.dart';

/// Central theme management service for AppRadar.
///
/// Controls Light and Dark mode transitions, persists user preference
/// to localStorage, and automatically updates [AppColors.isDark].
class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeService._internal() {
    _initTheme();
  }

  void _initTheme() {
    final stored = getStoredThemeMode();
    if (stored == 'light') {
      _themeMode = ThemeMode.light;
      AppColors.isDark = false;
    } else {
      // REKKI specification: Default to darkroom mission control
      _themeMode = ThemeMode.dark;
      AppColors.isDark = true;
    }
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      AppColors.isDark = (mode == ThemeMode.dark);
      setStoredThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
      notifyListeners();
    }
  }
}
