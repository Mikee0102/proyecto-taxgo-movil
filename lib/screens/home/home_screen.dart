import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) return const SizedBox();

    return StreamBuilder<UserModel?>(
      stream: authService.streamUserProfile(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tlax.Go'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar sesión',
                onPressed: () async => await authService.signOut(),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : (user.photoURL != null ? NetworkImage(user.photoURL!) : null),
                  child: (profile?.avatarUrl == null && user.photoURL == null)
                      ? const Icon(Icons.person, size: 46)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Bienvenido, ${profile?.name ?? user.displayName ?? "Viajero"}!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Chip(
                  label: Text('Rol: ${profile?.role ?? "user"}'),
                  backgroundColor: profile?.role == 'admin'
                      ? Colors.amber.shade100
                      : Colors.grey.shade200,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}