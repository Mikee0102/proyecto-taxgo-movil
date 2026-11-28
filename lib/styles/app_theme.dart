import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_theme_controller.dart';

abstract class AppThemeVariant {
  const AppThemeVariant();

  ThemeData build();
}

class _LightAppThemeVariant extends AppThemeVariant {
  const _LightAppThemeVariant();

  @override
  ThemeData build() => AppTheme._build(Brightness.light);
}

class _DarkAppThemeVariant extends AppThemeVariant {
  const _DarkAppThemeVariant();

  @override
  ThemeData build() => AppTheme._build(Brightness.dark);
}

abstract final class AppTheme {
  static const _lightVariant = _LightAppThemeVariant();
  static const _darkVariant = _DarkAppThemeVariant();

  static AppThemeVariant get _activeVariant =>
      AppThemeController.instance.isLightMode ? _lightVariant : _darkVariant;

  static ThemeData get current => _activeVariant.build();

  static ThemeData _build(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.onPrimary,
      tertiary: AppColors.accentLight,
      surface: AppColors.surface,
      onSurface: AppColors.textStrong,
      error: AppColors.error,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.headerGlass,
      foregroundColor: AppColors.onHeader,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTextStyles.appBarTitle,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.glassSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.glassBorder),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primary,
      contentTextStyle: TextStyle(
        color: AppColors.onPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: AppColors.accentLight,
      closeIconColor: AppColors.onPrimary,
      elevation: 6,
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.glassSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.error, width: 1.2),
      ),
      labelStyle: TextStyle(color: AppColors.text),
      hintStyle: TextStyle(color: AppColors.mutedLight),
    ),
    dividerColor: AppColors.border,
    textTheme:
        (brightness == Brightness.light
                ? ThemeData.light().textTheme
                : ThemeData.dark().textTheme)
            .copyWith(
              headlineSmall: AppTextStyles.headline,
              titleMedium: AppTextStyles.title,
              bodyMedium: AppTextStyles.body,
            ),
  );
}
