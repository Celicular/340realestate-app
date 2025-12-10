import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = AppTheme.primaryColor;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setSeedColor(Color color) {
    _seedColor = color;
    notifyListeners();
  }
}
