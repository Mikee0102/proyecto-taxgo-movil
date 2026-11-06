import 'package:firebase_auth/firebase_auth.dart';

class AuthErrors {
  static String getFriendlyErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Credenciales incorrectas. Por favor, verifica tu correo y contraseña.';
        case 'invalid-email':
          return 'Correo inválido. Ingresa un formato de correo electrónico correcto.';
        case 'email-already-in-use':
          return 'El correo ya está registrado. Intenta iniciar sesión o recuperar tu contraseña.';
        case 'weak-password':
          return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada. Contacta al soporte.';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Inténtalo más tarde.';
        case 'network-request-failed':
          return 'Error de conexión. Revisa tu acceso a internet.';
        default:
          return 'Ocurrió un error de autenticación (${error.code}).';
      }
    }

    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
}