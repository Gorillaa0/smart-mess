import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? deepLink;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.deepLink,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? 'Mess Notification',
      body: data['body'] ?? data['message'] ?? '',
      isRead: data['read'] == true || data['isRead'] == true,
      createdAt: parsedDate,
      deepLink: data['deepLink'] ?? data['category'],
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    String? deepLink,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      deepLink: deepLink ?? this.deepLink,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'deepLink': deepLink,
    };
  }
}
