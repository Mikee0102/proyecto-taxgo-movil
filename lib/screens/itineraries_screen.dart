import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ItinerariesScreen extends StatelessWidget {
  const ItinerariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5FD),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              Icon(Icons.route_rounded, color: AppColors.navy, size: 32),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Un buen viaje empieza con una buena ruta.',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionHeading(
          eyebrow: 'IDEAS PARA TU PRÓXIMA SALIDA',
          title: 'Itinerarios',
        ),
        const SizedBox(height: 12),
        const _ItineraryCard(
          number: '01',
          title: 'Un día entre historia y tradición',
          places: 'Tlaxcala · Ocotlán · Huamantla',
          duration: '1 día',
          icon: Icons.account_balance_rounded,
          accent: AppColors.amber,
        ),
        const SizedBox(height: 12),
        const _ItineraryCard(
          number: '02',
          title: 'Naturaleza para desconectar',
          places: 'La Malinche · Nanacamilpa',
          duration: 'Fin de semana',
          icon: Icons.forest_rounded,
          accent: AppColors.green,
        ),
        const SizedBox(height: 12),
        const _ItineraryCard(
          number: '03',
          title: 'Pueblos con mucho por contar',
          places: 'Tlaxco · Apizaco · Huamantla',
          duration: '2 días',
          icon: Icons.explore_rounded,
          accent: AppColors.blue,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EAF1)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.amber),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Estas son ideas para inspirarte. Próximamente podrás '
                  'personalizar tus rutas.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({
    required this.number,
    required this.title,
    required this.places,
    required this.duration,
    required this.icon,
    required this.accent,
  });

  final String number;
  final String title;
  final String places;
  final String duration;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
              Text(
                'RUTA $number',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                color: AppColors.muted,
                size: 15,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  places,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.navy,
                ),
                const SizedBox(width: 5),
                Text(
                  duration,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
