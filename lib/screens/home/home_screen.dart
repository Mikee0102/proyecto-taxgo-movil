
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    return StreamBuilder<UserModel?>(
      stream: authService.streamUserProfile(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        final String? avatarUrl =
            profile?.avatarUrl ?? user.photoURL;

        final bool hasAvatar =
            avatarUrl != null && avatarUrl.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tlax.Go'),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                onPressed: () async {
                  await authService.signOut();
                },
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundImage: hasAvatar
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: !hasAvatar
                        ? const Icon(Icons.person, size: 46)
                        : null,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '¡Bienvenido, ${profile?.name ?? user.displayName ?? "Viajero"}!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    user.email ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Chip(
                    label: Text(
                      'Rol: ${profile?.role ?? "user"}',
                    ),
                    backgroundColor: profile?.role == 'admin'
                        ? Colors.amber.shade100
                        : Colors.grey.shade200,
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Ver mapa'),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_circle),
                    label: const Text('Mi perfil'),
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
