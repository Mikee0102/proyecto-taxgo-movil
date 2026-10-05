import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [AppColors.navy, AppColors.navyLight, Color(0xFF164E63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'TU GUÍA PARA DESCUBRIR',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¿Qué es\nTlaxgo?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Una forma sencilla de vivir Tlaxcala. Encuentra lugares, '
                'conoce sus historias y arma una aventura a tu ritmo.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 23),
              const Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _HeroTag(icon: Icons.location_on_outlined, label: 'Destinos'),
                  _HeroTag(icon: Icons.map_outlined, label: 'Rutas'),
                  _HeroTag(icon: Icons.auto_awesome_outlined, label: 'Cultura'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionHeading(
          eyebrow: 'MUCHO POR DESCUBRIR',
          title: 'Tlaxcala, más cerca',
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.location_city_rounded,
                value: '60',
                label: 'municipios',
                color: AppColors.blue,
              ),
            ),
            SizedBox(width: 11),
            Expanded(
              child: _StatCard(
                icon: Icons.park_rounded,
                value: 'Un sinfín',
                label: 'de experiencias',
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const _SectionHeading(
          eyebrow: 'HECHO PARA EXPLORAR',
          title: 'Todo en un solo lugar',
        ),
        const SizedBox(height: 12),
        const _FeatureTile(
          icon: Icons.map_rounded,
          color: AppColors.blue,
          title: 'Encuentra tu próximo destino',
          description: 'Naturaleza, historia y rincones que sorprenden.',
        ),
        const SizedBox(height: 10),
        const _FeatureTile(
          icon: Icons.route_rounded,
          color: AppColors.amber,
          title: 'Planea una ruta a tu manera',
          description: 'Ideas para aprovechar cada momento de tu viaje.',
        ),
        const SizedBox(height: 10),
        const _FeatureTile(
          icon: Icons.favorite_rounded,
          color: AppColors.green,
          title: 'Conecta con lo local',
          description: 'Tradiciones, sabores y experiencias tlaxcaltecas.',
        ),
      ],
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
        border: Border.all(color: Colors.white.withValues(alpha: .13)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE7EBF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EBF1)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
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
