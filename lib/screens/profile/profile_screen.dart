
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _savingName = false;
  bool _uploadingImage = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _changeName(String currentName) async {
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar nombre de usuario'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre de usuario',
              hintText: 'Escribe tu nuevo nombre',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.trim().isEmpty) {
      return;
    }

    if (newName.trim() == currentName) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() => _savingName = true);

    try {
      await user.updateDisplayName(newName.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': newName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Nombre actualizado correctamente!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el nombre: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingName = false);
      }
    }
  }

  Future<void> _changePhoto() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (image == null) return;

      setState(() => _uploadingImage = true);

      final extension = image.path.split('.').last.toLowerCase();

      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_avatars')
          .child('${user.uid}.$extension');

      await storageRef.putFile(
        File(image.path),
        SettableMetadata(contentType: contentType),
      );

      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'avatarUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updatePhotoURL(downloadUrl);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Foto de perfil actualizada!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cambiar la foto: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        body: const Center(
          child: Text('Debes iniciar sesión.'),
        ),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: authService.streamUserProfile(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mi perfil')),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mi perfil')),
            body: const Center(
              child: Text('No se pudo cargar el perfil.'),
            ),
          );
        }

        final profile = snapshot.data;

        final name =
            profile?.name ?? user.displayName ?? 'Viajero';

        final email = user.email ?? 'Correo no disponible';

        final role = profile?.role ?? 'user';

        final avatarUrl =
            profile?.avatarUrl ?? user.photoURL;

        final hasAvatar =
            avatarUrl != null && avatarUrl.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi perfil'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: hasAvatar
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: !hasAvatar
                          ? const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.blueGrey,
                            )
                          : null,
                    ),

                    Material(
                      color: Colors.blue,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: _uploadingImage
                            ? null
                            : _changePhoto,
                        tooltip: 'Cambiar foto',
                        icon: _uploadingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextButton.icon(
                  onPressed: _uploadingImage
                      ? null
                      : _changePhoto,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Cambiar foto de perfil'),
                ),

                const SizedBox(height: 20),

                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Nombre de usuario'),
                        subtitle: Text(name),
                        trailing: IconButton(
                          tooltip: 'Editar nombre',
                          icon: const Icon(Icons.edit),
                          onPressed: _savingName
                              ? null
                              : () => _changeName(name),
                        ),
                      ),

                      if (_savingName)
                        const LinearProgressIndicator(),

                      const Divider(height: 1),

                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Correo electrónico'),
                        subtitle: Text(email),
                      ),

                      const Divider(height: 1),

                      ListTile(
                        leading: const Icon(Icons.verified_user),
                        title: const Text('Rol'),
                        subtitle: Text(role),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Regresar al inicio'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
