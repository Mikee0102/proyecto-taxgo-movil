import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../models/user_model.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onReturn, this.onSignOut});

  final VoidCallback? onReturn;
  final VoidCallback? onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _savingName = false;
  bool _uploadingImage = false;
  bool _isItineraryLocked = false;
  bool _canUseBiometrics = false;
  bool _isUpdatingSecurity = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final available = await BiometricService.isBiometricAvailable();
      final enabled = await BiometricService.isLockEnabled();
      if (!mounted) return;

      setState(() {
        _canUseBiometrics = available;
        _isItineraryLocked = enabled;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el bloqueo: $error')),
      );
    }
  }

  Future<void> _setItineraryLock(bool newValue) async {
    setState(() => _isUpdatingSecurity = true);
    try {
      final success = await BiometricService.setLockEnabled(newValue);
      if (!mounted) return;

      if (success) {
        setState(() => _isItineraryLocked = newValue);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo confirmar la autenticación.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el bloqueo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingSecurity = false);
      }
    }
  }

  List<Widget> get _signOutActions => widget.onSignOut == null
      ? const []
      : [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ];

  Future<void> _setLightMode(bool enabled) async {
    try {
      await AppThemeController.instance.setLightMode(enabled);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar el modo de color: $error')),
      );
    }
  }

  Future<void> _refreshProfile(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el perfil: $e')),
      );
    }
  }

  Future<void> _changeName(String currentName) async {
    var enteredName = currentName;
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar nombre de usuario'),
        content: TextFormField(
          initialValue: currentName,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) => enteredName = value,
          decoration: const InputDecoration(
            labelText: 'Nombre de usuario',
            hintText: 'Escribe tu nuevo nombre',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, enteredName.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (!mounted || newName == null || newName.trim().isEmpty) {
      return;
    }

    if (newName.trim() == currentName) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !mounted) return;

    setState(() => _savingName = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': newName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Nombre actualizado correctamente!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el nombre: $e')),
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
        imageQuality: 70,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (image == null) return;

      setState(() => _uploadingImage = true);

      // La foto se reduce a 300 px y se guarda como texto (base64)
      // directamente en Firestore, sin usar Firebase Storage.
      final bytes = await image.readAsBytes();
      final avatarData = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Firestore limita cada documento a 1 MB.
      if (avatarData.length > 700000) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La imagen es muy pesada.')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'avatarUrl': avatarData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Foto de perfil actualizada!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo cambiar la foto: $e')));
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
        appBar: AppBar(
          title: const Text('Mi perfil'),
          actions: _signOutActions,
        ),
        body: const Center(child: Text('Debes iniciar sesión.')),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: authService.streamUserProfile(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mi perfil'),
              actions: _signOutActions,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mi perfil'),
              actions: _signOutActions,
            ),
            body: const Center(child: Text('No se pudo cargar el perfil.')),
          );
        }

        final profile = snapshot.data;

        final name = profile?.name ?? user.displayName ?? 'Viajero';

        final email = user.email ?? 'Correo no disponible';

        final avatarUrl = profile?.avatarUrl ?? user.photoURL;

        final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi perfil'),
            centerTitle: true,
            actions: _signOutActions,
          ),
          body: RefreshIndicator(
            onRefresh: () => _refreshProfile(user.uid),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppThemeController.instance.isLightMode
                            ? const [Color(0xFF0C3970), Color(0xFF0879B5)]
                            : [AppColors.heroTop, AppColors.heroBottom],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.heroBorder),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -45,
                          right: -38,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.7,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: AppColors.surface
                                          .withValues(alpha: 0.12),
                                      backgroundImage: hasAvatar
                                          ? (avatarUrl.startsWith('data:')
                                                ? MemoryImage(
                                                    base64Decode(
                                                      avatarUrl.split(',').last,
                                                    ),
                                                  )
                                                : NetworkImage(avatarUrl)
                                                      as ImageProvider)
                                          : null,
                                      child: !hasAvatar
                                          ? Icon(
                                              Icons.person_rounded,
                                              size: 52,
                                              color: AppColors.onHero,
                                            )
                                          : null,
                                    ),
                                  ),
                                  Material(
                                    color: AppColors.accent,
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      onPressed: _uploadingImage
                                          ? null
                                          : _changePhoto,
                                      tooltip: 'Cambiar foto',
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 38,
                                            height: 38,
                                          ),
                                      padding: EdgeInsets.zero,
                                      icon: _uploadingImage
                                          ? SizedBox(
                                              width: 17,
                                              height: 17,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.navy,
                                              ),
                                            )
                                          : Icon(
                                              Icons.camera_alt_rounded,
                                              color: AppColors.navy,
                                              size: 19,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.onHero,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _uploadingImage
                                    ? null
                                    : _changePhoto,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.onHero,
                                ),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Cambiar foto de perfil'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Información de la cuenta',
                    style: TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProfileCard(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            10,
                            8,
                          ),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.accentDark,
                            ),
                          ),
                          title: Text(
                            'Nombre de usuario',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              name,
                              style: TextStyle(
                                color: AppColors.textStrong,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Editar nombre',
                            onPressed: _savingName
                                ? null
                                : () => _changeName(name),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: AppColors.accentDark,
                            ),
                          ),
                        ),
                        if (_savingName)
                          const LinearProgressIndicator(minHeight: 2),
                        Divider(height: 1, color: AppColors.border),
                        ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            8,
                          ),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.email_outlined,
                              color: AppColors.accentDark,
                            ),
                          ),
                          title: Text(
                            'Correo electrónico',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              email,
                              style: TextStyle(
                                color: AppColors.textStrong,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (_canUseBiometrics) ...[
                          Divider(height: 1, color: AppColors.border),
                          SwitchListTile(
                            title: const Text(
                              'Bloquear itinerarios con huella',
                            ),
                            subtitle: const Text(
                              'Solicitar huella o PIN al abrir tus rutas guardadas',
                            ),
                            secondary: const Icon(Icons.fingerprint),
                            value: _isItineraryLocked,
                            onChanged: _isUpdatingSecurity
                                ? null
                                : _setItineraryLock,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Apariencia',
                    style: TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildProfileCard(
                    child: Material(
                      color: Colors.transparent,
                      child: SwitchListTile.adaptive(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        secondary: Icon(
                          AppThemeController.instance.isLightMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_outlined,
                          color: AppColors.accentLight,
                        ),
                        title: const Text('Modo claro'),
                        subtitle: const Text(
                          'Cambia la luz de las superficies sin alterar la marca',
                        ),
                        value: AppThemeController.instance.isLightMode,
                        onChanged: _setLightMode,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed:
                          widget.onReturn ?? () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Regresar al inicio'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.inputBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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

  Widget _buildProfileCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.profileSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.profileBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
