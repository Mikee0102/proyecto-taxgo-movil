import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import './intinerario.dart';
import '../../styles/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Future<void> _refreshHome(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el inicio: $error')),
      );
    }
  }

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
        final role =
            profile?.role ??
            (user.uid == UserModel.adminUid ? 'admin' : 'user');
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
                onRefresh: () => _refreshHome(user.uid),
              ),
              const MapScreen(),
              ItinerariosScreen(
                isAdmin: role == 'admin',
                isActive: _selectedIndex == 2,
              ),
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
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Itinerarios',
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
    required Future<void> Function() onRefresh,
  }) {
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/icono.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Tlax.Go',
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
                    const SizedBox(height: 18),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Inspiración para tu viaje',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Lugares que hacen única a Tlaxcala.',
                      style: TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 205,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        children: [
                          _buildDestinationCard(
                            category: 'ARTE E HISTORIA',
                            title: 'Basílica de Ocotlán',
                            subtitle: 'Un ícono de Tlaxcala',
                            icon: Icons.church_rounded,
                            colors: const [
                              Color(0xFF175A76),
                              Color(0xFF09283F),
                            ],
                          ),
                          const SizedBox(width: 14),
                          _buildDestinationCard(
                            category: 'NATURALEZA',
                            title: 'La Malinche',
                            subtitle: 'Aire libre y paisajes',
                            icon: Icons.landscape_rounded,
                            colors: const [
                              Color(0xFF36765E),
                              Color(0xFF153D3A),
                            ],
                          ),
                          const SizedBox(width: 14),
                          _buildDestinationCard(
                            category: 'CULTURA',
                            title: 'Centro Histórico',
                            subtitle: 'Plazas llenas de historia',
                            icon: Icons.account_balance_rounded,
                            colors: const [
                              Color(0xFF9A6237),
                              Color(0xFF542E32),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard({
    required String category,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = 1),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  top: -28,
                  right: -20,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Icon(
                    icon,
                    size: 96,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.76),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
