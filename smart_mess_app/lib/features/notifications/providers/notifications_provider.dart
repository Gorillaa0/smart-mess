import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/notification_model.dart';

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  NotificationsNotifier() : super(const AsyncLoading()) {
    _load();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 500));
    state = AsyncData([
      NotificationModel(
        id: '1',
        title: 'Mess Off Approved',
        body: 'Your mess off for tomorrow lunch has been approved.',
        isRead: false,
        createdAt: DateTime.now(),
      ),
      NotificationModel(
        id: '2',
        title: 'Menu Updated',
        body: 'Dinner menu for tonight has changed.',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }

  void markAllRead() {
    state.whenData((notifications) {
      state = AsyncData(
        notifications.map((n) => NotificationModel(
          id: n.id,
          title: n.title,
          body: n.body,
          isRead: true,
          createdAt: n.createdAt,
        )).toList()
      );
    });
  }
}

final notificationsListProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationsNotifier();
});
