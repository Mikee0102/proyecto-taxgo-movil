import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/filter_option.dart';
import '../models/place.dart';
import '../styles/app_colors.dart';

class PlaceDetailCard extends StatelessWidget {
  final Place? place;
  final VoidCallback onClose;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const PlaceDetailCard({
    super.key,
    required this.place,
    required this.onClose,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  String _categoryLabel(PlaceCategory category) {
    for (final option in filterOptions) {
      if (option.id == category) return option.label;
    }
    return 'Lugar turístico';
  }

  String _categoryIcon(PlaceCategory category) {
    for (final option in filterOptions) {
      if (option.id == category) return option.icon;
    }
    return '📍';
  }

  Future<void> _openDirections(BuildContext context, Place currentPlace) async {
    final lat = currentPlace.location.latitude;
    final lon = currentPlace.location.longitude;

    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
    );

    try {
      final launched = await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la aplicación de mapas.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir cómo llegar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePlace(BuildContext context, Place currentPlace) async {
    final municipality = currentPlace.resolvedMunicipality;
    final lat = currentPlace.location.latitude.toStringAsFixed(5);
    final lon = currentPlace.location.longitude.toStringAsFixed(5);

    final text =
        '¡Mira este lugar en Tlaxcala!: ${currentPlace.name} ($municipality) - '
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';

    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enlace y detalles del lugar copiados al portapapeles.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (place == null) return const SizedBox.shrink();

    final currentPlace = place!;
    final municipality = currentPlace.resolvedMunicipality;
    final categoryText = _categoryLabel(currentPlace.category);
    final iconEmoji = _categoryIcon(currentPlace.category);

    return Positioned(
      bottom: 16,
      left: 16,
      right:
          84, // Deja espacio limpio a la derecha para el FloatingActionButton
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF5142038), Color(0xF5060B1D)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 24,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF082F49),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(iconEmoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            categoryText.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.accentLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    _ActionIconButton(
                      icon: Icons.ios_share_rounded,
                      tooltip: 'Compartir',
                      onTap: () => _sharePlace(context, currentPlace),
                    ),
                    const SizedBox(width: 6),
                    _ActionIconButton(
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: isFavorite
                          ? const Color(0xFFFF6B8A)
                          : Colors.white70,
                      backgroundColor: isFavorite
                          ? const Color(0xFF482136)
                          : null,
                      tooltip: 'Favorito',
                      onTap: onToggleFavorite,
                    ),
                    const SizedBox(width: 6),
                    _ActionIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Cerrar',
                      onTap: onClose,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 13),
            Text(
              currentPlace.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: AppColors.accentLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$municipality, Tlaxcala',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  size: 13,
                  color: Colors.white38,
                ),
                const SizedBox(width: 5),
                Text(
                  '${currentPlace.location.latitude.toStringAsFixed(4)}, '
                  '${currentPlace.location.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openDirections(context, currentPlace),
                icon: const Icon(Icons.directions_rounded, size: 19),
                label: const Text(
                  'Cómo llegar',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.navy,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? backgroundColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    this.iconColor = Colors.white70,
    this.backgroundColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 17),
      style: IconButton.styleFrom(
        foregroundColor: iconColor,
        backgroundColor: backgroundColor ?? const Color(0xFF0F172A),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: const CircleBorder(),
      ),
    );
  }
}
