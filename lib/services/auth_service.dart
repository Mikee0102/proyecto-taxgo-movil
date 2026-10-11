// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // En v7 es un singleton
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  // Stream para escuchar cambios de sesión en tiempo real
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Asegura la inicialización de GoogleSignIn v7
// En tu auth_service.dart
  Future<void> _ensureGoogleInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _googleSignIn.initialize(
        serverClientId: '889076176339-uea5q8576v30nj7k0qm1275je71m1lj7.apps.googleusercontent.com',
      );
      _isGoogleSignInInitialized = true;
    }
  }

  // Stream para obtener el perfil de Firestore en tiempo real
  Stream<UserModel?> streamUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // 1. Iniciar sesión con Correo y Contraseña
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // 2. Registro con Correo y Contraseña
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await cred.user?.updateDisplayName(name);

    await _createUserDoc(
      uid: cred.user!.uid,
      name: name,
      email: email.trim(),
      avatarUrl: null,
    );

    return cred;
  }

  // 3. Inicio de sesión con Google (Adaptado a google_sign_in 7.x)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      // En v7 se utiliza authenticate() en lugar de signIn()
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // authentication en v7 es sincrónico (sin await) y provee el idToken
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Para obtener el accessToken se solicitan los scopes mediante authorizationClient
      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: clientAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _createUserDoc(
          uid: user.uid,
          name: user.displayName ?? 'Usuario',
          email: user.email ?? '',
          avatarUrl: user.photoURL,
        );
      }

      return userCredential;
    } on GoogleSignInException catch (_) {
      // Si el usuario cancela la hoja de inicio de sesión o falla la interacción
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // 4. Crear documento del usuario si no existe
  Future<void> _createUserDoc({
    required String uid,
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userRef.update({
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 5. Cerrar sesión
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}