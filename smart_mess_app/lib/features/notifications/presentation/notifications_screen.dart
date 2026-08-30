import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsListProvider.notifier).markAllAsRead();
    });
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Clear All Notifications?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'This will remove all current announcements from your notification history.',
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notificationsListProvider.notifier).clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('CLEAR ALL', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsListProvider);
    final notifsList = notificationsState.valueOrNull ?? [];
    final unreadCount = notifsList.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF1B5E20),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Color(0xFF1B5E20), size: 24),
            SizedBox(width: 8),
            Text(
              'Mess Announcements',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 17),
            ),
          ],
        ),
        actions: [
          if (notifsList.isNotEmpty) ...[
            if (unreadCount > 0)
              IconButton(
                tooltip: 'Mark All as Read',
                icon: const Icon(Icons.done_all, color: Color(0xFF1B5E20), size: 20),
                onPressed: () {
                  ref.read(notificationsListProvider.notifier).markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All marked as read'), duration: Duration(seconds: 2)),
                  );
                },
              ),
            IconButton(
              tooltip: 'Clear All Notifications',
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 21),
              onPressed: () => _showClearAllDialog(context),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: notificationsState.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_off_outlined, size: 50, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Announcements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
                  const SizedBox(height: 6),
                  Text(
                    'You are all caught up! Broadcasts from your mess manager will appear here.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final timeStr = DateFormat('hh:mm a • dd MMM').format(notif.createdAt);
              final isUnread = !notif.isRead;

              return Dismissible(
                key: Key('notif_${notif.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, color: Colors.white, size: 22),
                      SizedBox(width: 6),
                      Text('Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                onDismissed: (_) {
                  ref.read(notificationsListProvider.notifier).clearNotification(notif.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification cleared'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () => ref.read(notificationsListProvider.notifier).refresh(),
                      ),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    if (isUnread) {
                      ref.read(notificationsListProvider.notifier).markAsRead(notif.id);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isUnread ? const Color(0xFFF9FFF9) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnread ? const Color(0xFF81C784) : Colors.grey.shade200,
                        width: isUnread ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isUnread ? const Color(0xFF1B5E20).withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isUnread ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.campaign,
                                      color: isUnread ? const Color(0xFF1B5E20) : Colors.grey.shade600,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Hostel H4 Mess',
                                    style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  if (isUnread) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE65100),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'NEW',
                                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      timeStr,
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      ref.read(notificationsListProvider.notifier).clearNotification(notif.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 14.5,
                              color: isUnread ? Colors.black : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif.body,
                            style: TextStyle(
                              color: isUnread ? Colors.grey.shade900 : Colors.grey.shade700,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
        error: (err, stack) => Center(child: Text('Failed to load notifications: $err')),
      ),
    );
  }
}
