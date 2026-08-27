import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Color(0xFF1B5E20), size: 24),
            SizedBox(width: 8),
            Text(
              'Mess Announcements',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 18),
            ),
          ],
        ),
      ),
      body: notificationsState.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none, size: 48, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Announcements Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Broadcasts from your mess manager will appear here in real-time.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: index == 0 ? const Color(0xFFA5D6A7) : Colors.grey.shade200,
                    width: index == 0 ? 1.4 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
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
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.campaign, color: Color(0xFF1B5E20), size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Hostel H4 Mess',
                                style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              timeStr,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notif.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 12.5, height: 1.35),
                      ),
                    ],
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
