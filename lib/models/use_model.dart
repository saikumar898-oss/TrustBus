import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;
  final String? phone;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.phone,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      phone: map['phone'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "email": email,
      "role": role,
      "phone": phone,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }
}
