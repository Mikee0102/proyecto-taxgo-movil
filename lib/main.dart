import 'package:flutter/material.dart';

import 'screens/about_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/itineraries_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const TlaxgoApp());
}

class TlaxgoApp extends StatelessWidget {
  const TlaxgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tlaxgo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
          primary: AppColors.navy,
          secondary: AppColors.blue,
        ),
        fontFamily: 'Roboto',
      ),
      home: const TlaxgoHome(),
    );
  }
}

class TlaxgoHome extends StatefulWidget {
  const TlaxgoHome({super.key});

  @override
  State<TlaxgoHome> createState() => _TlaxgoHomeState();
}

class _TlaxgoHomeState extends State<TlaxgoHome> {
  int _selectedIndex = 0;

  static const _titles = ['Conoce Tlaxgo', 'Explora Tlaxcala', 'Itinerarios'];
  static const _screens = [AboutScreen(), ExploreScreen(), ItinerariesScreen()];

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            icon: const Icon(Icons.logout_rounded, color: AppColors.navy),
            title: const Text('¿Cerrar sesión?'),
            content: const Text(
              'La autenticación todavía no está conectada. Este botón está listo '
              'para enlazarse con el servicio de acceso de la app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );

    if (!mounted || shouldSignOut != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Conecta la autenticación para cerrar la sesión.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: .45),
                ),
              ),
              child: const Icon(
                Icons.explore_outlined,
                color: AppColors.blue,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Tlaxgo',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: _screens),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.blue.withValues(alpha: .18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.info_outline_rounded),
            selectedIcon: Icon(Icons.info_rounded),
            label: 'Tlaxgo',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route_rounded),
            label: 'Itinerarios',
          ),
        ],
      ),
    );
  }
}