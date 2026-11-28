import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefKey = 'lock_itinerary_enabled';

  // Guarda la última vez que se desbloqueó para no pedir huella cada 5 segundos
  static DateTime? _lastUnlockedTime;
  static const Duration _gracePeriod = Duration(minutes: 3);

  /// Verifica si el teléfono tiene sensor de huella o Face ID configurado
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Lee si el usuario activó el bloqueo desde su perfil
  static Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Activa o desactiva la preferencia (pide huella al activarlo)
  static Future<bool> setLockEnabled(bool value) async {
    if (value) {
      final authenticated = await authenticate(
        reason: 'Confirma tu identidad para activar el bloqueo de itinerarios',
        forceAuth: true,
      );
      if (!authenticated) return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    return true;
  }

  /// Ejecuta la validación biométrica (con respaldo de PIN/Patrón del teléfono)
  static Future<bool> authenticate({
    String reason = 'Verifica tu identidad para ver tu itinerario',
    bool forceAuth = false,
  }) async {
    // Si aún está dentro del tiempo de gracia, permite el paso sin pedir huella
    if (!forceAuth && _lastUnlockedTime != null) {
      if (DateTime.now().difference(_lastUnlockedTime!) < _gracePeriod) {
        return true;
      }
    }

    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        _lastUnlockedTime = DateTime.now();
      }
      return didAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Llamar al cerrar sesión en auth_service.dart para limpiar el tiempo de gracia
  static void clearSession() {
    _lastUnlockedTime = null;
  }
}
