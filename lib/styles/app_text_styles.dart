import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const appBarTitle = TextStyle(
    color: AppColors.surface,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static const headline = TextStyle(
    color: AppColors.primary,
    fontWeight: FontWeight.w800,
  );

  static const title = TextStyle(
    color: AppColors.textStrong,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(color: AppColors.text, height: 1.5);

  static const sectionTitle = TextStyle(
    color: AppColors.primary,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  static const cardTitle = TextStyle(
    color: AppColors.primary,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
}
