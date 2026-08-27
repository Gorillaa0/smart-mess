import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../core/models/notification_model.dart';

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  Timer? _pollTimer;

  NotificationsNotifier() : super(const AsyncLoading()) {
    _fetchLive();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchLive());
  }

  Future<void> _fetchLive() async {
    // 1. Direct Google Cloud Firestore runQuery (Real-Time Cloud Sync)
    try {
      final dio = Dio();
      final res = await dio.post(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'structuredQuery': {
            'from': [{'collectionId': 'notifications'}]
          }
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200 && res.data is List) {
        final List results = res.data;
        final notifs = <NotificationModel>[];

        for (final item in results) {
          if (item is Map && item['document'] != null) {
            final doc = item['document'] as Map;
            final fields = (doc['fields'] as Map?) ?? {};

            final id = fields['id']?['stringValue'] ?? (doc['name']?.toString().split('/').last ?? 'notif');
            final title = fields['title']?['stringValue'] ?? 'Announcement';
            final body = fields['body']?['stringValue'] ?? '';
            final category = fields['category']?['stringValue'] ?? 'alert';
            final read = fields['read']?['booleanValue'] ?? false;
            final createdAtStr = fields['createdAt']?['stringValue'] ?? '';
            final parsedDate = DateTime.tryParse(createdAtStr) ?? DateTime.now();

            notifs.add(NotificationModel(
              id: id,
              title: title,
              body: body,
              isRead: read,
              createdAt: parsedDate,
              deepLink: category,
            ));
          }
        }

        if (notifs.isNotEmpty) {
          // Sort newest first
          notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          state = AsyncData(notifs);
          return;
        }
      }
    } catch (e) {
      debugPrint('[NOTIFS FETCH ERROR]: $e');
    }

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

