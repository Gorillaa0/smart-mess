import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String studentId;
  final String category;
  final String description;
  final String status; // open, in_progress, resolved
  final DateTime createdAt;
  final String? response;

  ComplaintModel({
    required this.id,
    required this.studentId,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.response,
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ComplaintModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      response: data['response'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'response': response,
    };
  }
}
