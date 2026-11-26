import 'package:flutter/material.dart';
import '../styles/app_colors.dart';

class MapSearchBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const MapSearchBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: TextEditingController.fromValue(
          TextEditingValue(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
          ),
        ),
        onChanged: onChanged,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: AppColors.navy,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Buscar lugar o municipio (ej. Tlaxcala, Huamantla)...',
          hintStyle: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.navy),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.muted,
                    size: 20,
                  ),
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
            borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
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