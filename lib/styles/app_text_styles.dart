import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle get appBarTitle => TextStyle(
    color: AppColors.onHeader,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get headline =>
      TextStyle(color: AppColors.textStrong, fontWeight: FontWeight.w800);

  static TextStyle get title =>
      TextStyle(color: AppColors.textStrong, fontWeight: FontWeight.w600);

  static TextStyle get body => TextStyle(color: AppColors.text, height: 1.5);

  static TextStyle get sectionTitle => TextStyle(
    color: AppColors.textStrong,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  static TextStyle get cardTitle => TextStyle(
    color: AppColors.textStrong,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
}
