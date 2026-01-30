import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

enum AppThemeMode { light, dark, system, auto }

class ThemeProvider with ChangeNotifier {
  AppThemeMode _appThemeMode = AppThemeMode.system;
  ThemeMode _computedThemeMode = ThemeMode.system;
  Color _seedColor = AppTheme.primaryColor;
  Timer? _themeTimer;
  bool _isAutoLight = true;
  DateTime? _lastThemeSwitch;

  ThemeMode get themeMode => _computedThemeMode;
  AppThemeMode get appThemeMode => _appThemeMode;
  Color get seedColor => _seedColor;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt('appThemeMode') ?? 2; // Default to system
      _appThemeMode = AppThemeMode.values[modeIndex];

      if (_appThemeMode == AppThemeMode.auto) {
        _isAutoLight = prefs.getBool('isAutoLight') ?? true;
        final lastSwitchMillis = prefs.getInt('lastThemeSwitch');
        if (lastSwitchMillis != null) {
          _lastThemeSwitch = DateTime.fromMillisecondsSinceEpoch(lastSwitchMillis);
        }
        _startAutoThemeTimer();
      } else {
        _computedThemeMode = _appThemeModeToThemeMode(_appThemeMode);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('appThemeMode', _appThemeMode.index);
      await prefs.setBool('isAutoLight', _isAutoLight);
      if (_lastThemeSwitch != null) {
        await prefs.setInt('lastThemeSwitch', _lastThemeSwitch!.millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('Error saving theme preferences: $e');
    }
  }

  void setThemeMode(AppThemeMode mode) {
    _appThemeMode = mode;
    _stopAutoThemeTimer();

    if (mode == AppThemeMode.auto) {
      _startAutoThemeTimer();
    } else {
      _computedThemeMode = _appThemeModeToThemeMode(mode);
    }

    notifyListeners();
    _savePreferences();
  }

  void _startAutoThemeTimer() {
    _stopAutoThemeTimer(); // Ensure no duplicate timers

    // Check if we need to switch based on last switch time
    if (_lastThemeSwitch != null) {
      final timeSinceSwitch = DateTime.now().difference(_lastThemeSwitch!);
      if (timeSinceSwitch.inHours >= 12) {
        // Switch theme if 12 hours have passed
        _toggleAutoTheme();
      }
    } else {
      // First time - initialize
      _lastThemeSwitch = DateTime.now();
      _savePreferences();
    }

    // Update computed theme mode
    _computedThemeMode = _isAutoLight ? ThemeMode.light : ThemeMode.dark;

    // Start periodic timer (12 hours = 43200000 milliseconds)
    _themeTimer = Timer.periodic(const Duration(hours: 12), (timer) {
      _toggleAutoTheme();
    });
  }

  void _toggleAutoTheme() {
    _isAutoLight = !_isAutoLight;
    _lastThemeSwitch = DateTime.now();
    _computedThemeMode = _isAutoLight ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _savePreferences();
  }

  void _stopAutoThemeTimer() {
    _themeTimer?.cancel();
    _themeTimer = null;
  }

  ThemeMode _appThemeModeToThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.auto:
        return _isAutoLight ? ThemeMode.light : ThemeMode.dark;
      case AppThemeMode.system:
      default:
        return ThemeMode.system;
    }
  }

  void setSeedColor(Color color) {
    _seedColor = color;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopAutoThemeTimer();
    super.dispose();
  }
}
