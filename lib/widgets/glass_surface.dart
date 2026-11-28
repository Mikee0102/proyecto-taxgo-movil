import 'dart:ui';

import 'package:flutter/material.dart';

import '../styles/app_colors.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.tintColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? tintColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentLight.withValues(alpha: 0.14),
            blurRadius: 26,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tintColor ?? AppColors.glassSurface,
              borderRadius: borderRadius,
              border: Border.all(
                color: borderColor ?? AppColors.glassBorder,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
