import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import 'glass_surface.dart';

class MapSearchBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const MapSearchBar({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(16),
      child: TextField(
        controller: TextEditingController.fromValue(
          TextEditingValue(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
          ),
        ),
        onChanged: onChanged,
        style: TextStyle(
          color: AppColors.textStrong,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          filled: false,
          hintText: 'Buscar lugar o municipio (ej. Tlaxcala, Huamantla)...',
          hintStyle: TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.accent),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: AppColors.muted, size: 20),
                  onPressed: () => onChanged(''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.accent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
