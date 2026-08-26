import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? studentId;
  final String? messId;
  final String? hostelId;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.studentId,
    this.messId,
    this.hostelId,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      status: data['status'] ?? 'active',
      studentId: data['studentId'],
      messId: data['messId'],
      hostelId: data['hostelId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'studentId': studentId,
      'messId': messId,
      'hostelId': hostelId,
    };
  }
}
