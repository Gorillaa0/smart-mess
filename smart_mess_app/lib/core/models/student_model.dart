import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String name;
  final String email;
  final String hostel;
  final String roomNumber;
  final String course;
  final int year;

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.hostel,
    required this.roomNumber,
    required this.course,
    required this.year,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      hostel: data['hostel'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      course: data['course'] ?? '',
      year: data['year'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'hostel': hostel,
      'roomNumber': roomNumber,
      'course': course,
      'year': year,
    };
  }
}
