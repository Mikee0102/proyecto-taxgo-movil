import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.navy,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.heroTop,
    required this.heroBorder,
    required this.heroText,
  });

  final String id;
  final String name;
  final Color primary;
  final Color navy;
  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color heroTop;
  final Color heroBorder;
  final Color heroText;

  static const tlaxGo = AppPalette(
    id: 'original',
    name: 'Tlax.Go',
    primary: Color(0xFF071126),
    navy: Color(0xFF060B1D),
    accent: Color(0xFF12BDF2),
    accentLight: Color(0xFF29C6F6),
    accentDark: Color(0xFF078EB9),
    heroTop: Color(0xFF071126),
    heroBorder: Color(0xFF12BDF2),
    heroText: Color(0xFFB7C4DA),
  );
}

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final instance = AppThemeController._();
  static const _lightModePreferenceKey = 'light_mode_enabled';

  bool _isLightMode = true;

  AppPalette get palette => AppPalette.tlaxGo;
  bool get isLightMode => _isLightMode;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _isLightMode = preferences.getBool(_lightModePreferenceKey) ?? true;
  }

  Future<void> setLightMode(bool enabled) async {
    if (_isLightMode == enabled) return;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_lightModePreferenceKey, enabled);
    _isLightMode = enabled;
    notifyListeners();
  }
}
