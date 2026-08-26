import 'package:cloud_firestore/cloud_firestore.dart';

class MealModel {
  final String id;
  final String title;
  final String type; // Breakfast, Lunch, Snacks, Dinner
  final String items;
  final DateTime startTime;
  final DateTime endTime;
  final bool isSpecial;

  MealModel({
    required this.id,
    required this.title,
    required this.type,
    required this.items,
    required this.startTime,
    required this.endTime,
    this.isSpecial = false,
  });

  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MealModel(
      id: doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? '',
      items: data['items'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      isSpecial: data['isSpecial'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'items': items,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isSpecial': isSpecial,
    };
  }
}
