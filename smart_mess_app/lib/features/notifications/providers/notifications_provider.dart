import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/notification_model.dart';

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  Timer? _pollTimer;

  NotificationsNotifier() : super(const AsyncLoading()) {
    _fetchLive();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchLive());
  }

  Future<void> _fetchLive() async {
    try {
      // 1. Fetch from Express Backend API (Instant real-time sync)
      final dio = Dio();
      final res = await dio.get('http://localhost:3001/notifications').timeout(const Duration(milliseconds: 1500));
      if (res.statusCode == 200 && res.data != null && res.data['notifications'] != null) {
        final rawList = res.data['notifications'] as List;
        final list = rawList.map((n) {
          DateTime parsedDate = DateTime.tryParse(n['createdAt']?.toString() ?? '') ?? DateTime.now();
          return NotificationModel(
            id: n['id'] ?? 'n_${DateTime.now().millisecondsSinceEpoch}',
            title: n['title'] ?? 'Announcement',
            body: n['body'] ?? '',
            isRead: n['read'] == true,
            createdAt: parsedDate,
            deepLink: n['category'],
          );
        }).toList();

        state = AsyncData(list);
        return;
      }
    } catch (_) {}

    // 2. Fallback to Cloud Firestore
    try {
      final snap = await FirebaseFirestore.instance.collection('notifications').get().timeout(const Duration(milliseconds: 1500));
      if (snap.docs.isNotEmpty) {
        final list = snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList();
        state = AsyncData(list);
        return;
      }
    } catch (_) {}

    // 3. Fallback default data
    if (state is AsyncLoading) {
      state = AsyncData([
        NotificationModel(
          id: 'notif_default_1',
          title: '⏰ Dinner Mess-Off Cutoff at 05:00 PM',
          body: 'Students planning to dine outside must apply for mess-off before 05:00 PM.',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        NotificationModel(
          id: 'notif_default_2',
          title: '🍲 Special Sunday Feast Announced',
          body: 'Special Paneer Butter Masala, Pulao, Gulab Jamun served this Sunday for Dinner.',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final notificationsListProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationsNotifier();
});

