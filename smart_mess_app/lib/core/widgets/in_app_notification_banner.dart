import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../router/app_router.dart';
import '../../features/notifications/providers/notifications_provider.dart';
import 'top_notification_overlay.dart';

class InAppNotificationWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const InAppNotificationWrapper({super.key, required this.child});

  @override
  ConsumerState<InAppNotificationWrapper> createState() => _InAppNotificationWrapperState();
}

class _InAppNotificationWrapperState extends ConsumerState<InAppNotificationWrapper> {
  final Set<String> _seenNotifIds = {};
  late final DateTime _sessionStartTime;
  bool _initializedStorage = false;

  @override
  void initState() {
    super.initState();
    // Record current session startup time. Old messages sent before this time will NEVER pop up as banners.
    _sessionStartTime = DateTime.now();
    _loadSeenIds();
  }

  Future<void> _loadSeenIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('seen_notification_ids') ?? [];
      _seenNotifIds.addAll(savedList);
    } catch (_) {}
    if (mounted) {
      setState(() => _initializedStorage = true);
    }
  }

  Future<void> _persistSeenIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('seen_notification_ids', _seenNotifIds.toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Listen for incoming notifications from Riverpod stream
    ref.listen<AsyncValue<List<NotificationModel>>>(notificationsListProvider, (prev, next) {
      final list = next.valueOrNull ?? [];
      if (list.isEmpty) return;

      final isAuth = ref.read(authStateProvider);

      for (final n in list) {
        // If not seen before, check if it qualifies for live pop-up
        if (!_seenNotifIds.contains(n.id)) {
          _seenNotifIds.add(n.id);
          _persistSeenIds();

          // Rules for showing top pop-up banner:
          // 1. User must be logged in (NEVER show on login screen / during logout)
          // 2. The notification must have been broadcast LIVE during the active session (createdAt >= sessionStartTime)
          // 3. Must not be an old/past message
          final isLiveBroadcast = n.createdAt.isAfter(_sessionStartTime) ||
              n.createdAt.isAfter(DateTime.now().subtract(const Duration(minutes: 1)));

          if (isAuth && isLiveBroadcast) {
            TopNotificationOverlay.show(
              notification: n,
              senderOverride: (n.deepLink ?? '').contains('admin')
                  ? 'Institute Administration'
                  : 'Hostel H4 Mess',
            );
          }
        }
      }
    });

    return widget.child;
  }
}
