import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _isInitialLoad = true;

  @override
  Widget build(BuildContext context) {
    // Listen for live new notifications from Riverpod
    ref.listen<AsyncValue<List<NotificationModel>>>(notificationsListProvider, (prev, next) {
      final list = next.valueOrNull ?? [];
      if (list.isEmpty) return;

      if (_isInitialLoad) {
        // Record all existing notification IDs when app first opens
        for (final n in list) {
          _seenNotifIds.add(n.id);
        }
        _isInitialLoad = false;
        return;
      }

      // Check for incoming notifications
      for (final n in list) {
        if (!_seenNotifIds.contains(n.id)) {
          _seenNotifIds.add(n.id);
          // Trigger the Top Floating Push Pop-Up Overlay!
          TopNotificationOverlay.show(
            notification: n,
            senderOverride: (n.deepLink ?? '').contains('admin') ? 'Institute Administration' : 'Hostel H4 Mess',
          );
          break; // Pop up the newest notification
        }
      }
    });

    return widget.child;
  }
}
