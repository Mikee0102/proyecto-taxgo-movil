import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role; // 'user' o 'admin'

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? 'Usuario',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'],
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}