import 'package:cloud_firestore/cloud_firestore.dart';

class BillModel {
  final String id;
  final String studentId;
  final String month; // e.g., 'August 2024'
  final double baseFee;
  final double messOffDeductions;
  final double extras;
  final double totalAmount;
  final String status; // paid, unpaid, pending

  BillModel({
    required this.id,
    required this.studentId,
    required this.month,
    required this.baseFee,
    required this.messOffDeductions,
    required this.extras,
    required this.totalAmount,
    required this.status,
  });

  factory BillModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BillModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      month: data['month'] ?? '',
      baseFee: (data['baseFee'] ?? 0).toDouble(),
      messOffDeductions: (data['messOffDeductions'] ?? 0).toDouble(),
      extras: (data['extras'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'unpaid',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'month': month,
      'baseFee': baseFee,
      'messOffDeductions': messOffDeductions,
      'extras': extras,
      'totalAmount': totalAmount,
      'status': status,
    };
  }
}
