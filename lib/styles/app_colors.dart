import 'package:flutter/material.dart';

import 'app_theme_controller.dart';

abstract final class AppColors {
  static bool get _isLight => AppThemeController.instance.isLightMode;

  static Color get background =>
      _isLight ? const Color(0xFFEAF0F6) : const Color(0xFF12161C);
  static Color get surface =>
      _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1D242B);
  static Color get glassSurface =>
      _isLight ? const Color(0xDFFFFFFF) : const Color(0xB31D242B);
  static Color get profileSurface =>
      _isLight ? const Color(0xFFDCEEFF) : const Color(0xFF1D242B);
  static Color get profileBorder =>
      _isLight ? const Color(0xFF7CC7EA) : const Color(0xFF3A454F);
  static Color get glassBorder =>
      AppPalette.tlaxGo.accentDark.withValues(alpha: _isLight ? 0.42 : 0.38);
  static Color get primary =>
      _isLight ? AppPalette.tlaxGo.primary : AppPalette.tlaxGo.accentLight;
  static Color get onPrimary =>
      _isLight ? Colors.white : const Color(0xFF071126);
  static Color get navy => AppPalette.tlaxGo.navy;
  static Color get accent => AppPalette.tlaxGo.accent;
  static Color get accentLight => AppPalette.tlaxGo.accentLight;
  static Color get accentDark =>
      _isLight ? AppPalette.tlaxGo.accentDark : AppPalette.tlaxGo.accentLight;
  static Color get text =>
      _isLight ? const Color(0xFF334155) : const Color(0xFFE0E7F0);
  static Color get textStrong =>
      _isLight ? const Color(0xFF071126) : const Color(0xFFF1F5F9);
  static Color get muted =>
      _isLight ? const Color(0xFF475569) : const Color(0xFFB9C7D8);
  static Color get mutedLight =>
      _isLight ? const Color(0xFF64748B) : const Color(0xFF91A5BA);
  static Color get border =>
      _isLight ? const Color(0xFFCCD9E6) : const Color(0xFF303A43);
  static Color get inputBorder =>
      _isLight ? const Color(0xFFD9E2EC) : const Color(0xFF3A454F);
  static Color get error =>
      _isLight ? const Color(0xFFEF4444) : const Color(0xFFF87171);
  static Color get header => _isLight ? AppPalette.tlaxGo.primary : navy;
  static Color get headerGlass =>
      _isLight ? const Color(0xEB071126) : const Color(0xEB060B1D);
  static const onHeader = Colors.white;
  static Color get heroTop => _isLight
      ? Color.lerp(AppPalette.tlaxGo.primary, surface, 0.88)!
      : const Color(0xFF20282F);
  static Color get heroBottom => _isLight
      ? Color.lerp(AppPalette.tlaxGo.navy, surface, 0.92)!
      : const Color(0xFF252F35);
  static Color get heroBorder => _isLight
      ? AppPalette.tlaxGo.accent.withValues(alpha: 0.2)
      : AppPalette.tlaxGo.accent.withValues(alpha: 0.3);
  static Color get heroText => _isLight ? text : AppPalette.tlaxGo.heroText;
  static Color get heroTextOnDark => AppPalette.tlaxGo.heroText;
  static Color get onHero => const Color(0xFFFFFFFF);
  static Color get heroPanel =>
      _isLight ? const Color(0xFF14243C) : const Color(0xFF20282F);
  static Color get itineraryTop =>
      _isLight ? const Color(0xFF0B1C36) : const Color(0xFF121B2A);
  static Color get itineraryBottom =>
      _isLight ? const Color(0xFF143F60) : const Color(0xFF1D2D40);
  static const itineraryText = Color(0xFFF1F5F9);
  static const itineraryAccent = Color(0xFF66D9FF);
  static Color get loginTop => heroTop;
  static Color get loginBottom => heroBottom;
  static const favorite = Color(0xFF29C6F6);
}
