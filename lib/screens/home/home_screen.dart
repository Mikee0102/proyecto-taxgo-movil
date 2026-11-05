
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../rutas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No hay una sesión iniciada.'),
        ),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: authService.streamUserProfile(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        final String nombre =
            profile?.name.isNotEmpty == true
                ? profile!.name
                : user.displayName ?? 'Viajero';

        final String? avatarUrl = profile?.avatarUrl ?? user.photoURL;

        final bool tieneAvatar =
            avatarUrl != null && avatarUrl.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tlax.Go'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authService.signOut();

                  if (context.mounted) {
                    Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    );
                  }
                },
              ),
            ],
          ),

          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage:
                        tieneAvatar ? NetworkImage(avatarUrl!) : null,
                    child: !tieneAvatar
                        ? const Icon(
                            Icons.person,
                            size: 55,
                            color: Colors.teal,
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '¡Bienvenido, $nombre!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    user.email ?? 'Sin correo registrado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Chip(
                    avatar: const Icon(
                      Icons.verified_user,
                      color: Colors.teal,
                    ),
                    label: Text(
                      'Rol: ${profile?.role ?? 'user'}',
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Explorar mapa turístico'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RutasScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.favorite),
                      label: const Text('Probar rutas favoritas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade50,
                        foregroundColor: Colors.pink.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person),
                      label: const Text('Mi perfil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
