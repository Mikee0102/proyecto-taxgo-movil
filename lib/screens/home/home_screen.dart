import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../rutas_screen.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Future<void> _signOut() async {
    await AuthService().signOut();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay una sesión iniciada.')),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: authService.streamUserProfile(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.name.isNotEmpty == true
            ? profile!.name
            : user.displayName ?? 'Viajero';
        final avatarUrl = profile?.avatarUrl ?? user.photoURL;

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeContent(
                name: name,
                email: user.email ?? 'Sin correo registrado',
                avatarUrl: avatarUrl,
                role: profile?.role ?? 'user',
              ),
              const MapScreen(),
              const RutasScreen(),
              ProfileScreen(onReturn: () => setState(() => _selectedIndex = 0)),
            ],
          ),
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
              iconTheme: WidgetStateProperty.resolveWith((states) {
                return IconThemeData(
                  color: states.contains(WidgetState.selected)
                      ? AppColors.accent
                      : Colors.white60,
                );
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  color: states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white60,
                  fontSize: 12,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              backgroundColor: AppColors.navy,
              indicatorColor: AppColors.accent.withValues(alpha: 0.18),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Mapa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.route_outlined),
                  selectedIcon: Icon(Icons.route_rounded),
                  label: 'Rutas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeContent({
    required String name,
    required String email,
    required String? avatarUrl,
    required String role,
  }) {
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(20, 10, 14, 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.explore_outlined,
                      color: AppColors.accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tlaxgo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '60 municipios',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded),
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.accent.withValues(
                            alpha: 0.14,
                          ),
                          backgroundImage: hasAvatar
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: hasAvatar
                              ? null
                              : const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.navy,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Hola, $name!',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.accent,
                          size: 20,
                          semanticLabel: 'Rol: $role',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Explora a tu manera',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Encuentra lugares y experiencias para tu próximo viaje.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildExploreCard(
                    icon: Icons.map_outlined,
                    title: 'Mapa turístico',
                    subtitle: 'Descubre lugares cerca de ti',
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  _buildExploreCard(
                    icon: Icons.favorite_border_rounded,
                    title: 'Rutas favoritas',
                    subtitle: 'Inspírate para tu próxima aventura',
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      constraints: const BoxConstraints(minHeight: 270),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.heroTop, AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.heroBorder),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -9,
            top: 24,
            child: Icon(
              Icons.explore_rounded,
              size: 118,
              color: AppColors.accent.withValues(alpha: 0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✨  DESCUBRE TLAXCALA',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Una aventura\nen cada destino',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: 29,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tradición, naturaleza y cultura te esperan.',
                style: TextStyle(
                  color: AppColors.heroText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => setState(() => _selectedIndex = 1),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.navy,
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Explorar lugares'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.accentDark, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.mutedLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
