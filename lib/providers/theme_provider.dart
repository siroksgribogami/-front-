import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Провайдер темы и размера шрифта
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  double _fontScale = 1.0; // 0.8 .. 1.4

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  double get fontScale => _fontScale;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('themeMode') ?? 0; // 0=light, 1=dark, 2=system
    final scale = prefs.getDouble('fontScale') ?? 1.0;

    _themeMode = ThemeMode.values[modeIndex];
    _fontScale = scale.clamp(0.8, 1.4);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.8, 1.4);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontScale', _fontScale);
  }

  /// Метка для слайдера
  String get fontScaleLabel {
    if (_fontScale <= 0.85) return 'Мелкий';
    if (_fontScale <= 0.95) return 'Маленький';
    if (_fontScale <= 1.05) return 'Обычный';
    if (_fontScale <= 1.2) return 'Крупный';
    return 'Очень крупный';
  }
}
