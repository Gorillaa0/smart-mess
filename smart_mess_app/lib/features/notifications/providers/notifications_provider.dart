import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/notification_model.dart';

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  Timer? _pollTimer;
  final Set<String> _readNotifIds = {};
  final Set<String> _clearedNotifIds = {};
  bool _prefsLoaded = false;

  NotificationsNotifier() : super(const AsyncLoading()) {
    _init();
  }

  Future<void> _init() async {
    await _loadLocalPreferences();
    await _fetchLive();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _fetchLive());
  }

  Future<void> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final read = prefs.getStringList('student_read_notification_ids') ?? [];
      final cleared = prefs.getStringList('student_cleared_notification_ids') ?? [];
      _readNotifIds.addAll(read);
      _clearedNotifIds.addAll(cleared);
      _prefsLoaded = true;
    } catch (_) {
      _prefsLoaded = true;
    }
  }

  Future<void> _saveLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('student_read_notification_ids', _readNotifIds.toList());
      await prefs.setStringList('student_cleared_notification_ids', _clearedNotifIds.toList());
    } catch (_) {}
  }

  Future<void> _fetchLive() async {
    if (!_prefsLoaded) await _loadLocalPreferences();

    // 1. Direct Cloud Firestore query via REST & SDK
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
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && res.data is List) {
        final List results = res.data;
        final notifs = <NotificationModel>[];

        for (final item in results) {
          if (item is Map && item['document'] != null) {
            final doc = item['document'] as Map;
            final fields = (doc['fields'] as Map?) ?? {};

            final id = fields['id']?['stringValue'] ?? (doc['name']?.toString().split('/').last ?? 'notif');
            
            // If student has explicitly cleared this notification, skip it
            if (_clearedNotifIds.contains(id)) continue;

            final title = fields['title']?['stringValue'] ?? 'Announcement';
            final body = fields['body']?['stringValue'] ?? '';
            final category = fields['category']?['stringValue'] ?? 'alert';
            final serverRead = fields['read']?['booleanValue'] ?? fields['isRead']?['booleanValue'] ?? false;
            final isRead = serverRead || _readNotifIds.contains(id);
            final createdAtStr = fields['createdAt']?['stringValue'] ?? '';
            final parsedDate = DateTime.tryParse(createdAtStr) ?? DateTime.now();

            notifs.add(NotificationModel(
              id: id,
              title: title,
              body: body,
              isRead: isRead,
              createdAt: parsedDate,
              deepLink: category,
            ));
          }
        }

        notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = AsyncData(notifs);
        return;
      }
    } catch (e) {
      debugPrint('[NOTIFS FETCH ERROR]: $e');
    }

    // 2. Fallback default announcements only if not cleared
    if (state is AsyncLoading || state.valueOrNull == null || state.valueOrNull!.isEmpty) {
      final defaultNotifs = <NotificationModel>[];
      
      if (!_clearedNotifIds.contains('notif_default_1')) {
        defaultNotifs.add(NotificationModel(
          id: 'notif_default_1',
          title: '⏰ Dinner Mess-Off Cutoff at 05:00 PM',
          body: 'Students planning to dine outside must apply for mess-off before 05:00 PM.',
          isRead: _readNotifIds.contains('notif_default_1'),
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ));
      }

      if (!_clearedNotifIds.contains('notif_default_2')) {
        defaultNotifs.add(NotificationModel(
          id: 'notif_default_2',
          title: '🍲 Special Sunday Feast Announced',
          body: 'Special Paneer Butter Masala, Pulao, Gulab Jamun served this Sunday for Dinner.',
          isRead: _readNotifIds.contains('notif_default_2') || true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ));
      }

      state = AsyncData(defaultNotifs);
    }
  }

  // ─── Student Actions ────────────────────────────────────────────────────────

  /// Mark single notification as read (clears unread badge)
  void markAsRead(String notifId) {
    _readNotifIds.add(notifId);
    _saveLocalPreferences();

    final currentList = state.valueOrNull ?? [];
    final updatedList = currentList.map((n) {
      if (n.id == notifId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    state = AsyncData(updatedList);
  }

  /// Mark all current notifications as read
  void markAllAsRead() {
    final currentList = state.valueOrNull ?? [];
    for (final n in currentList) {
      _readNotifIds.add(n.id);
    }
    _saveLocalPreferences();

    final updatedList = currentList.map((n) => n.copyWith(isRead: true)).toList();
    state = AsyncData(updatedList);
  }

  /// Clear single notification from student view
  void clearNotification(String notifId) {
    _clearedNotifIds.add(notifId);
    _readNotifIds.add(notifId);
    _saveLocalPreferences();

    final currentList = state.valueOrNull ?? [];
    final updatedList = currentList.where((n) => n.id != notifId).toList();
    state = AsyncData(updatedList);
  }

  /// Clear all notifications from student view
  void clearAllNotifications() {
    final currentList = state.valueOrNull ?? [];
    for (final n in currentList) {
      _clearedNotifIds.add(n.id);
      _readNotifIds.add(n.id);
    }
    _saveLocalPreferences();
    state = const AsyncData([]);
  }

  // ─── Manager Actions ────────────────────────────────────────────────────────

  /// Delete broadcast permanently from Cloud Firestore
  Future<void> deleteBroadcast(String notifId) async {
    // 1. Instant local removal
    clearNotification(notifId);

    // 2. Delete from Firestore SDK
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notifId).delete().timeout(const Duration(seconds: 3));
    } catch (_) {}

    // 3. Fallback REST DELETE
    try {
      final dio = Dio();
      await dio.delete(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/notifications/$notifId?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    await _fetchLive();
  }

  Future<void> refresh() async {
    await _fetchLive();
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

