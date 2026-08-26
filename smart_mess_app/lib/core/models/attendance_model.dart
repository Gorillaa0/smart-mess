import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String mealId;
  final DateTime scannedAt;
  final String status; // present

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.mealId,
    required this.scannedAt,
    required this.status,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      mealId: data['mealId'] ?? '',
      scannedAt: (data['scannedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'present',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'mealId': mealId,
      'scannedAt': Timestamp.fromDate(scannedAt),
      'status': status,
    };
  }
}
