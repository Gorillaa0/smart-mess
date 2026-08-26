import 'package:cloud_firestore/cloud_firestore.dart';

class MessOffModel {
  final String id;
  final String studentId;
  final String mealId;
  final DateTime date;
  final String status; // pending, approved, cancelled

  MessOffModel({
    required this.id,
    required this.studentId,
    required this.mealId,
    required this.date,
    required this.status,
  });

  factory MessOffModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessOffModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      mealId: data['mealId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'mealId': mealId,
      'date': Timestamp.fromDate(date),
      'status': status,
    };
  }
}
