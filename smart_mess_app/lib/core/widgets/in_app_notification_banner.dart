import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
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
  bool _firstPayloadProcessed = false;

  @override
  void initState() {
    super.initState();
    // Record exact moment this app instance/session was opened
    _sessionStartTime = DateTime.now();
    _loadSeenIds();
  }

  Future<void> _loadSeenIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('seen_notification_ids') ?? [];
      _seenNotifIds.addAll(savedList);
    } catch (_) {}
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

      // 1. On initial app boot, silently mark all existing historical notifications as seen
      // so past messages (sent hours or days ago) never trigger a popup banner
      if (!_firstPayloadProcessed) {
        _firstPayloadProcessed = true;
        for (final n in list) {
          _seenNotifIds.add(n.id);
        }
        _persistSeenIds();
        return;
      }

      // 2. Only newly broadcast messages that arrive during active usage will trigger the live banner
      for (final n in list) {
        if (!_seenNotifIds.contains(n.id)) {
          _seenNotifIds.add(n.id);
          _persistSeenIds();

          // Only pop up if created during this active session (live broadcast)
          if (n.createdAt.isAfter(_sessionStartTime)) {
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
