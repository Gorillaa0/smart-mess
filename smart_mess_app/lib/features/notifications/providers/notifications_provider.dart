import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/notification_model.dart';

final notificationsListProvider = StreamProvider<List<NotificationModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) {
      return [
        NotificationModel(
          id: 'notif_default_1',
          title: '⏰ Dinner Mess-Off Cutoff at 05:00 PM',
          body: 'Students planning to dine outside must apply for mess-off before 05:00 PM.',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        NotificationModel(
          id: 'notif_default_2',
          title: '🍲 Special Sunday Feast Announced',
          body: 'Special Paneer Butter Masala, Pulao, Gulab Jamun served this Sunday for Dinner.',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    }
    return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
  });
});

