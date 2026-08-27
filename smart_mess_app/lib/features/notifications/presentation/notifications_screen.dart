import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref.read(notificationsListProvider.notifier).markAllRead();
            },
          )
        ],
      ),
      body: notificationsState.when(
        data: (notifications) {
          if (notifications.isEmpty) return const Center(child: Text('No notifications'));
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: notif.isRead ? Colors.grey : const Color(0xFF2E7D32),
                ),
                title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(notif.body),
                trailing: Text(
                  '${notif.createdAt.hour}:${notif.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                tileColor: notif.isRead ? Colors.transparent : Colors.green.withOpacity(0.05),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
