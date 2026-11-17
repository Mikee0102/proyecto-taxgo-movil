import 'package:flutter/material.dart';
import '../../utils/auth_guard.dart';
import '../home/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthGuard(child: HomeScreen());
  }
}