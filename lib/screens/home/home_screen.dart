import 'dart:async';

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import './intinerario.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_theme_controller.dart';
import '../../widgets/glass_surface.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _heroPage = 0;
  final Connectivity _connectivity = Connectivity();
  final PageController _heroController = PageController();
  Timer? _heroTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool? _hasNetworkConnection;

  static const _heroImages = [
    'assets/images/destinations/huamantla.jpg',
    'assets/images/destinations/cacaxtla.jpg',
    'assets/images/destinations/malinche.jpg',
    'assets/images/destinations/luciernagas.jpg',
    'assets/images/destinations/ixtenco.jpg',
    'assets/images/destinations/tlaxco.jpg',
  ];
  static const _heroPlaceNames = [
    'HUAMANTLA',
    'CACAXTLA',
    'LA MALINCHE',
    'SANTUARIO DE LUCIÉRNAGAS',
    'IXTENCO',
    'TLAXCO',
  ];

  @override
  void initState() {
    super.initState();
    AppThemeController.instance.addListener(_onThemeChanged);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivity,
    );
    _checkConnectivity();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_heroController.hasClients) return;
      final nextPage = (_heroPage + 1) % _heroImages.length;
      _heroController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _connectivitySubscription?.cancel();
    _heroController.dispose();
    AppThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (mounted) _updateConnectivity(results);
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo comprobar la conexión: ${error.message}'),
        ),
      );
    }
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    final previous = _hasNetworkConnection;
    if (previous == isConnected) return;

    setState(() => _hasNetworkConnection = isConnected);

    final messenger = ScaffoldMessenger.of(context);
    if (!isConnected) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Sin conexión. Los cambios de Firestore se guardarán y se enviarán al reconectarte.',
            ),
          ),
        );
    } else if (previous == false) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Conexión detectada. Sincronizando...')),
        );
      unawaited(_confirmPendingWrites());
    }
  }

  Future<void> _confirmPendingWrites() async {
    try {
      await FirebaseFirestore.instance.waitForPendingWrites();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Sincronización completada.')),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo confirmar la sincronización. Revisa la conexión y los permisos de la cuenta: $error',
            ),
          ),
        );
    }
  }

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

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeContent(
                name: name,
                email: user.email ?? 'Sin correo registrado',
                avatarUrl: profile?.avatarUrl ?? user.photoURL,
                onRefresh: () => _refreshHome(user.uid),
              ),
              MapScreen(onSignOut: _signOut),
              ItinerariosScreen(
                isAdmin: role == 'admin',
                isActive: _selectedIndex == 2,
                onSignOut: _signOut,
              ),
              ProfileScreen(
                onReturn: () => setState(() => _selectedIndex = 0),
                onSignOut: _signOut,
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: GlassSurface(
                borderRadius: BorderRadius.circular(26),
                tintColor: AppColors.headerGlass,
                borderColor: AppColors.accentLight.withValues(alpha: 0.32),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    indicatorColor: AppColors.accent.withValues(alpha: 0.2),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      return IconThemeData(
                        color: states.contains(WidgetState.selected)
                            ? AppColors.onHeader
                            : AppColors.onHeader.withValues(alpha: 0.82),
                      );
                    }),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      return TextStyle(
                        color: states.contains(WidgetState.selected)
                            ? AppColors.onHeader
                            : AppColors.onHeader.withValues(alpha: 0.82),
                        fontSize: 11,
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
                    backgroundColor: Colors.transparent,
                    indicatorColor: AppColors.accent.withValues(alpha: 0.2),
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
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
              ),
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
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHomeHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildUserAvatar(avatarUrl),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¡Hola, $name!',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textStrong,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '¿Qué quieres descubrir hoy?',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Tlaxcala',
                                  style: TextStyle(
                                    color: AppColors.textStrong,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Inspiración para tu viaje',
                        style: TextStyle(
                          color: AppColors.textStrong,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Lugares que hacen única a Tlaxcala.',
                        style: TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 246,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          children: [
                            _buildDestinationCard(
                              category: 'ARTE E HISTORIA',
                              title: 'Huamantla',
                              subtitle: 'Tapetes y tradición',
                              icon: Icons.palette_rounded,
                              imageUrl:
                                  'assets/images/destinations/huamantla.jpg',
                            ),
                            const SizedBox(width: 14),
                            _buildDestinationCard(
                              category: 'NATURALEZA',
                              title: 'La Malinche',
                              subtitle: 'Aire libre y paisajes',
                              icon: Icons.landscape_rounded,
                              imageUrl:
                                  'assets/images/destinations/malinche.jpg',
                            ),
                            const SizedBox(width: 14),
                            _buildDestinationCard(
                              category: 'ARQUEOLOGÍA',
                              title: 'Cacaxtla',
                              subtitle: 'Arte prehispánico',
                              icon: Icons.account_balance_rounded,
                              imageUrl:
                                  'assets/images/destinations/cacaxtla.jpg',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071126),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        border: Border(
          bottom: BorderSide(color: AppColors.accent.withValues(alpha: 0.55)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF071126).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
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
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/images/icono.jpg', fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Tlax.Go',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.onHeader,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '60 municipios',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _signOut,
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.accent,
                minimumSize: const Size(40, 40),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String? avatarUrl) {
    Widget fallback() => Container(
      color: AppColors.accent.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, color: AppColors.accentLight, size: 26),
    );

    final trimmedUrl = avatarUrl?.trim();
    if (trimmedUrl == null || trimmedUrl.isEmpty) {
      return ClipOval(
        child: SizedBox(width: 44, height: 44, child: fallback()),
      );
    }

    final ImageProvider<Object> image;
    if (trimmedUrl.startsWith('data:')) {
      final separator = trimmedUrl.indexOf(',');
      if (separator < 0) {
        return ClipOval(
          child: SizedBox(width: 44, height: 44, child: fallback()),
        );
      }
      try {
        image = MemoryImage(base64Decode(trimmedUrl.substring(separator + 1)));
      } on FormatException {
        return ClipOval(
          child: SizedBox(width: 44, height: 44, child: fallback()),
        );
      }
    } else {
      image = NetworkImage(trimmedUrl);
    }

    return ClipOval(
      child: SizedBox(
        width: 44,
        height: 44,
        child: Image(
          image: image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback(),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.heroBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textStrong.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _heroController,
                itemCount: _heroImages.length,
                onPageChanged: (page) => setState(() => _heroPage = page),
                itemBuilder: (context, index) => Image.asset(
                  _heroImages[index],
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xE6071126),
                      const Color(0x73071126),
                      const Color(0x18071126),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_heroImages.length, (index) {
                  final isActive = index == _heroPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(left: 5),
                    width: isActive ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          color: AppColors.accent,
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _heroPlaceNames[_heroPage],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.onHero,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 21),
                  Text(
                    'Una aventura en\ncada destino',
                    style: TextStyle(
                      color: AppColors.onHero,
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tradición, naturaleza y cultura te esperan.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _selectedIndex = 1),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.near_me_rounded, size: 18),
                      label: const Text(
                        'Explorar el mapa',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard({
    required String category,
    required String title,
    required String subtitle,
    required IconData icon,
    required String imageUrl,
  }) {
    final borderRadius = BorderRadius.circular(22);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = 1),
        borderRadius: borderRadius,
        child: Ink(
          width: 266,
          decoration: BoxDecoration(borderRadius: borderRadius),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.itineraryTop,
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 118,
                      color: AppColors.accent.withValues(alpha: 0.28),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x12071126), Color(0xD0071126)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xE6071126),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 15, color: AppColors.accentLight),
                        const SizedBox(width: 7),
                        Text(
                          category,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.7),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      blurRadius: 7,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.accentLight,
                              size: 17,
                            ),
                          ],
                        ),
                      ],
                    ),
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
