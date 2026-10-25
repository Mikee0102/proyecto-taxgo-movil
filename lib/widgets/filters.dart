// lib/widgets/filters.dart
import 'package:flutter/material.dart';
import '../models/filter_option.dart';

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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0EA5E9) // Color sky-500
                      : const Color(0xE6020617), // Color slate-950 con opacidad
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF38BDF8) // Color sky-400
                        : const Color(0xFF1E293B), // Color slate-800
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : const Color(0xFFCBD5E1), // slate-300
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