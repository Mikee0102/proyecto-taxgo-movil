import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'styles/app_theme.dart';
import 'utils/app_routes.dart';
import 'utils/auth_guard.dart';
import 'screens/home/home_screen.dart';

//// xd
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TlaxGoApp());
}

class TlaxGoApp extends StatelessWidget {
  const TlaxGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tlax.Go',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthWrapper(),
      routes: {
        AppRoutes.home: (context) => const AuthGuard(child: HomeScreen()),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
      },
    );
  }
}
