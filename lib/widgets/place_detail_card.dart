import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/filter_option.dart';
import '../models/place.dart';

class PlaceDetailCard extends StatelessWidget {
  final Place? place;
  final VoidCallback onClose;
  final VoidCallback? onToggleFavorite;

  const PlaceDetailCard({
    super.key,
    required this.place,
    required this.onClose,
    this.onToggleFavorite,
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
          content: Text('Enlace y detalles del lugar copiados al portapapeles.'),
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
      right: 84, // Deja espacio limpio a la derecha para el FloatingActionButton
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xF2020617),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E293B)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Badge de categoría y botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF082F49),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF0C4A6E)),
                  ),
                  child: Text(
                    '$iconEmoji  ${categoryText.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Row(
                  children: [
                    _ActionIconButton(
                      icon: Icons.share,
                      tooltip: 'Compartir',
                      onTap: () => _sharePlace(context, currentPlace),
                    ),
                    const SizedBox(width: 6),
                    _ActionIconButton(
                      icon: currentPlace.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      iconColor: currentPlace.isFavorite
                          ? Colors.pinkAccent
                          : Colors.white70,
                      tooltip: 'Favorito',
                      onTap: onToggleFavorite ??
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Favoritos sincronizados próximamente.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    ),
                    const SizedBox(width: 6),
                    _ActionIconButton(
                      icon: Icons.close,
                      tooltip: 'Cerrar',
                      onTap: onClose,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Nombre del lugar
            Text(
              currentPlace.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 6),

            // Municipio y ubicación en Tlaxcala
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 15,
                  color: Colors.lightBlueAccent,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$municipality, Tlaxcala',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Coordenadas de referencia
            Text(
              'Coords: ${currentPlace.location.latitude.toStringAsFixed(4)}, '
              '${currentPlace.location.longitude.toStringAsFixed(4)}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 12),

            // Botón Cómo llegar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openDirections(context, currentPlace),
                icon: const Icon(Icons.near_me, size: 16),
                label: const Text(
                  'Cómo llegar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 4,
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
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    this.iconColor = Colors.white70,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}