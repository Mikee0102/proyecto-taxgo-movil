import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.travel_explore_rounded,
                color: AppColors.blue,
                size: 30,
              ),
              SizedBox(width: 13),
              Expanded(
                child: Text(
                  '¿Qué se te antoja descubrir hoy?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionHeading(
          eyebrow: 'ELIGE TU EXPERIENCIA',
          title: 'Explora por categoría',
        ),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CategoryChip(icon: Icons.auto_awesome, label: 'Todos'),
            _CategoryChip(icon: Icons.forest, label: 'Naturaleza'),
            _CategoryChip(icon: Icons.account_balance, label: 'Cultura'),
            _CategoryChip(icon: Icons.hiking, label: 'Aventura'),
          ],
        ),
        const SizedBox(height: 22),
        const _SectionHeading(
          eyebrow: 'LUGARES PARA RECORDAR',
          title: 'Destinos',
        ),
        const SizedBox(height: 12),
        const _DestinationCard(
          icon: Icons.nightlight_round,
          tag: 'NANACAMILPA',
          title: 'Santuario de las Luciérnagas',
          description:
              'Una experiencia mágica entre bosques, ideal para conectar con la naturaleza.',
          color: AppColors.green,
        ),
        const SizedBox(height: 12),
        const _DestinationCard(
          icon: Icons.account_balance_rounded,
          tag: 'HUAMANTLA',
          title: 'Tradición y cultura viva',
          description:
              'Descubre calles llenas de historia, arte popular y sabores locales.',
          color: AppColors.amber,
        ),
        const SizedBox(height: 12),
        const _DestinationCard(
          icon: Icons.terrain_rounded,
          tag: 'TLAXCO',
          title: 'Montaña y aventura',
          description:
              'Paisajes, aire fresco y rincones perfectos para una escapada.',
          color: AppColors.blue,
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isSelected = label == 'Todos';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.navy : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSelected ? AppColors.navy : const Color(0xFFE1E7EF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isSelected ? AppColors.blue : AppColors.muted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.icon,
    required this.tag,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String tag;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF1)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: .8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 29),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
