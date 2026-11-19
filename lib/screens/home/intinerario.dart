
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../styles/app_colors.dart';

class ItinerariosScreen extends StatelessWidget {
  const ItinerariosScreen({super.key});

  // UID del administrador que publica los itinerarios desde la WEB.
  static const String adminUid = 'zF3VlnHCltQnsped1wXfmIaMiZo1';

  // Conexión con la misma colección utilizada por Tlax.Go WEB.
  Stream<QuerySnapshot<Map<String, dynamic>>> _obtenerItinerarios() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(adminUid)
        .collection('itinerarios')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Itinerarios',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descubre Tlaxcala',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Conoce diferentes recorridos turísticos y '
              'descubre la historia, cultura y naturaleza '
              'que Tlaxcala tiene para ofrecerte.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Recorridos recomendados',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Escucha los cambios de Firebase en tiempo real.
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _obtenerItinerarios(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _mensaje(
                    'No se pudieron cargar los itinerarios. '
                    'Verifica tu conexión y los permisos de Firebase.',
                    Icons.error_outline_rounded,
                  );
                }

                final documentos = snapshot.data?.docs ?? [];

                if (documentos.isEmpty) {
                  return _mensaje(
                    'Todavía no hay itinerarios publicados. '
                    'Cuando se publique uno desde la WEB, aparecerá aquí.',
                    Icons.map_outlined,
                  );
                }

                return Column(
                  children: documentos.map((documento) {
                    final itinerario = documento.data();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildItinerarioCard(itinerario),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _mensaje(String mensaje, IconData icono) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            icono,
            size: 42,
            color: AppColors.accentDark,
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerarioCard(Map<String, dynamic> itinerario) {
    final nombre = itinerario['title']?.toString() ?? 'Sin título';

    final descripcion =
        itinerario['description']?.toString() ??
        'Descubre este recorrido turístico de Tlaxcala.';

    final dias = itinerario['days'] is List
        ? itinerario['days'] as List
        : [];

    int minutosTotales = 0;
    final lugares = <String>[];

    for (final dia in dias) {
      if (dia is! Map) continue;

      final actividades = dia['activities'];

      if (actividades is! List) continue;

      for (final actividad in actividades) {
        if (actividad is! Map) continue;

        final minutos = actividad['duration_minutes'];

        if (minutos is num) {
          minutosTotales += minutos.toInt();
        }

        final titulo = actividad['title']?.toString().trim() ?? '';

        if (titulo.isNotEmpty && !lugares.contains(titulo)) {
          lugares.add(titulo);
        }
      }
    }

    final duracion = minutosTotales > 0
        ? _formatearDuracion(minutosTotales)
        : '${dias.length} ${dias.length == 1 ? 'día' : 'días'}';

    final lugaresTexto = lugares.isEmpty
        ? 'Consulta las actividades de este itinerario.'
        : lugares.join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: AppColors.accentDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 18,
                color: AppColors.accentDark,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Duración aproximada: $duracion',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Lugares del recorrido:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            lugaresTexto,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearDuracion(int minutos) {
    final horas = minutos ~/ 60;
    final restantes = minutos % 60;

    if (horas == 0) return '$restantes minutos';
    if (restantes == 0) {
      return '$horas ${horas == 1 ? 'hora' : 'horas'}';
    }

    return '$horas h $restantes min';
  }
}
