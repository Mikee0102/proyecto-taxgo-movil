import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'app_routes.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({required this.child, super.key});

  final Widget child;

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  Stream<User?>? _sessionChanges;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _sessionChanges = AuthService().verifiedAuthStateChanges;
  }

  void _redirectToLogin() {
    if (_isRedirecting) return;
    _isRedirecting = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final currentRoute = ModalRoute.of(context)?.settings.name;

      Navigator.of(context).pushNamedAndRemoveUntil<void>(
        AppRoutes.login,
        (route) => false,
        arguments: AppRoutes.safeReturnTo(currentRoute),
      );
    });
  }

  void _retrySessionCheck() {
    setState(() {
      _isRedirecting = false;
      _sessionChanges = AuthService().verifiedAuthStateChanges;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _sessionChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudo verificar la sesión.'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _retrySessionCheck,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.data == null) {
          _redirectToLogin();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _isRedirecting = false;
        return widget.child;
      },
    );
  }
}
