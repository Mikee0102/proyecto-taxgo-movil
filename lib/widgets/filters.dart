// lib/widgets/filters.dart
import 'package:flutter/material.dart';

import '../models/filter_option.dart';
import '../styles/app_colors.dart';

class Filters extends StatelessWidget {
  final PlaceCategory activeCategory;
  final ValueChanged<PlaceCategory> onCategoryChange;

  const Filters({
    super.key,
    required this.activeCategory,
    required this.onCategoryChange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filterOptions.length,
        itemBuilder: (context, index) {
          final option = filterOptions[index];
          final isActive = activeCategory == option.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onCategoryChange(option.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accent
                      : AppColors.navy.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppColors.accentLight
                        : AppColors.textStrong,
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(option.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppColors.surface
                            : AppColors.heroText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
