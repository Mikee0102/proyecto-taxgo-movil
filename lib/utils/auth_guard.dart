import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({required this.child, super.key});

  final Widget child;

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late final StreamSubscription<User?> _authSubscription;
  bool _isCheckingAuth = true;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthChange,
    );
  }

  void _handleAuthChange(User? user) {
    if (!mounted) return;

    setState(() => _isCheckingAuth = false);

    if (user == null && !_isRedirecting) {
      _isRedirecting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil<void>(
          '/auth/login',
          (route) => false,
        );
      });
    } else if (user != null) {
      _isRedirecting = false;
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isRedirecting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return widget.child;
  }
}
