import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/weekly_menu.dart';
import '../../../core/constants/h4_students_data.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/meal_rating_service.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../events/providers/events_provider.dart';
import '../../attendance/providers/student_attendance_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../orders/providers/orders_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayMenu = WeeklyMenuData.getTodayMenu(now);
    final activeState = WeeklyMenuData.getActiveMealState(now);
    final dateString = DateFormat('dd MMMM yyyy').format(now);

    final notifsAsync = ref.watch(notificationsListProvider);
    final notifsList = notifsAsync.valueOrNull ?? [];
    final unreadNotifsCount = notifsList.where((n) => !n.isRead).length;

    final eventsAsync = ref.watch(eventsListProvider);
    final eventsList = eventsAsync.valueOrNull ?? [];
    final attStats = ref.watch(studentAttendanceStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
              ),
              child: const Icon(Icons.restaurant_menu, color: Color(0xFF1B5E20), size: 18),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Smart Mess',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Hostel Number 4 • Dining',
                    style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Announcements & Notifications',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: unreadNotifsCount > 0 ? const Color(0xFFFFF3E0) : Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: unreadNotifsCount > 0 ? const Color(0xFFFFB74D) : Colors.green.shade200,
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    unreadNotifsCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                    color: unreadNotifsCount > 0 ? const Color(0xFFE65100) : const Color(0xFF1B5E20),
                    size: 17,
                  ),
                ),
                if (unreadNotifsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD32F2F),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$unreadNotifsCount',
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              ref.read(notificationsListProvider.notifier).markAllAsRead();
              context.push('/notifications');
            },
          ),
          IconButton(
            tooltip: 'QR Attendance Scanner',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade200, width: 0.8),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Color(0xFFE65100), size: 17),
            ),
            onPressed: () => context.push('/scanner'),
          ),
          IconButton(
            tooltip: 'Logout',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade200, width: 0.8),
              ),
              child: const Icon(Icons.logout, color: Colors.redAccent, size: 17),
            ),
            onPressed: () => AuthService.performLogout(ref, context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          children: [
            // 1. TOP PROFILE & DAY BANNER (HOSTEL NUMBER 4 - REAL STUDENT DATA)
            _buildProfileBanner(context, todayMenu, dateString, ref.watch(currentStudentProvider)),
            const SizedBox(height: 14),

            // 1.5 LIVE UNREAD BROADCAST NOTICE (Instant read & dismiss support)
            if (unreadNotifsCount > 0 && notifsList.any((n) => !n.isRead)) ...[
              _buildLiveBroadcastCard(context, notifsList.firstWhere((n) => !n.isRead), ref),
              const SizedBox(height: 14),
            ],

            // 2. TODAY'S MEALS TIMELINE & PRICING ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF1B5E20)),
                    const SizedBox(width: 6),
                    Text(
                      "TODAY'S SCHEDULE (${todayMenu.dayEnglish.toUpperCase()})",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1B5E20), letterSpacing: 0.5),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showWeeklyMenuModal(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.shade200, width: 0.8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.menu_book, size: 12, color: Color(0xFF6A1B9A)),
                        SizedBox(width: 4),
                        Text(
                          'Full Week Menu',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildDailyScheduleRow(ref, todayMenu, now),
            const SizedBox(height: 18),

            // 3. ACTIVE / NEXT MEAL HERO CARD (Dynamically advances upon scanning)
            _buildActiveMealCard(context, ref, todayMenu, WeeklyMenuData.getTomorrowMenu(now), now),
            const SizedBox(height: 22),

            // 4. COLORFUL QUICK ACTIONS SECTION
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "QUICK ACTIONS & SERVICES",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildColorfulQuickActionsGrid(context),
            const SizedBox(height: 20),

            // 5. BILLING & EVENTS SUMMARY CARDS
            Row(
              children: [
                Expanded(
                  child: () {
                    final student = ref.watch(currentStudentProvider);
                    final allScans = ref.watch(liveAttendanceProvider);
                    final cleanReg = student.registrationNo.trim().toLowerCase();
                    final cleanRoll = student.rollNo.trim().toLowerCase();
                    final studentScans = allScans.where((s) {
                      final sr = s.registrationNo.trim().toLowerCase();
                      final sl = s.rollNo.trim().toLowerCase();
                      return sr == cleanReg || sr == cleanRoll || sl == cleanReg || sl == cleanRoll;
                    }).toList();

                    // Group by date to avoid double counting and match bill_screen.dart exactly
                    final Map<String, List<H4MealScanRecord>> scansByDate = {};
                    for (final scan in studentScans) {
                      final dateKey = DateFormat('yyyy-MM-dd').format(scan.scannedAt.toLocal());
                      scansByDate.putIfAbsent(dateKey, () => []).add(scan);
                    }

                    int liveBillAmount = 0;
                    int mealsCount = 0;
                    scansByDate.forEach((dateKey, dayScans) {
                      final date = DateTime.tryParse(dateKey) ?? DateTime.now();
                      final isSun = date.weekday == DateTime.sunday;
                      final isWed = date.weekday == DateTime.wednesday;

                      final bEaten = dayScans.any((s) => s.mealType.toLowerCase().contains('breakfast'));
                      final lEaten = dayScans.any((s) => s.mealType.toLowerCase().contains('lunch'));
                      final dEaten = dayScans.any((s) => s.mealType.toLowerCase().contains('dinner'));

                      if (bEaten) {
                        liveBillAmount += isSun ? 0 : 25;
                        mealsCount++;
                      }
                      if (lEaten) {
                        liveBillAmount += isSun ? 100 : 50;
                        mealsCount++;
                      }
                      if (dEaten) {
                        liveBillAmount += isWed ? 100 : 50;
                        mealsCount++;
                      }
                    });

                    final remaining = student.depositedAmount - liveBillAmount;

                    return _colorfulSummaryCard(
                      context,
                      title: 'Current Mess Bill',
                      value: '₹$liveBillAmount',
                      subtitle: '₹$remaining left of ₹${student.depositedAmount}',
                      icon: Icons.receipt_long,
                      startColor: const Color(0xFFFFF8E1),
                      endColor: const Color(0xFFFFECB3),
                      borderColor: const Color(0xFFFFD54F),
                      textColor: const Color(0xFFE65100),
                      onTap: () => context.push('/bill'),
                    );
                  }(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: () {
                    final myOrders = ref.watch(studentOrdersListProvider);
                    final activeOrder = myOrders.isNotEmpty ? myOrders.first : null;
                    final statusText = activeOrder != null ? activeOrder.status : 'Available Now';
                    final subtitleText = activeOrder != null 
                        ? '${activeOrder.foodItemName} (₹${activeOrder.totalBill}) • $statusText'
                        : 'Order Egg Roll & Paneer Roll';

                    return _colorfulSummaryCard(
                      context,
                      title: 'Special Food & Orders',
                      value: activeOrder != null ? 'Status: $statusText' : 'Rolls & Snacks',
                      subtitle: subtitleText,
                      icon: Icons.fastfood,
                      startColor: const Color(0xFFFFEBEE),
                      endColor: const Color(0xFFFFCDD2),
                      borderColor: const Color(0xFFEF9A9A),
                      textColor: const Color(0xFFC62828),
                      onTap: () => context.push('/order-food'),
                    );
                  }(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5.5 LIVE FOOD ORDER STATUS BANNER (SHOWS RECENT ORDER HISTORY & CANCELLATION REASON ON DASHBOARD)
            () {
              final myOrders = ref.watch(studentOrdersListProvider);
              if (myOrders.isEmpty) return const SizedBox.shrink();
              final latestOrder = myOrders.first;
              final isCancelled = latestOrder.status == 'Cancelled';
              final isDelivered = latestOrder.status == 'Delivered';
              final isPreparing = latestOrder.status == 'Preparing';

              Color bannerBg = Colors.orange.shade50;
              Color bannerBorder = Colors.orange.shade300;
              Color bannerText = Colors.orange.shade900;
              IconData statusIcon = Icons.hourglass_top;

              if (isDelivered) {
                bannerBg = Colors.green.shade50;
                bannerBorder = Colors.green.shade300;
                bannerText = Colors.green.shade900;
                statusIcon = Icons.check_circle;
              } else if (isPreparing) {
                bannerBg = Colors.blue.shade50;
                bannerBorder = Colors.blue.shade300;
                bannerText = Colors.blue.shade900;
                statusIcon = Icons.soup_kitchen;
              } else if (isCancelled) {
                bannerBg = Colors.red.shade50;
                bannerBorder = Colors.red.shade300;
                bannerText = Colors.red.shade900;
                statusIcon = Icons.cancel;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: bannerBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: bannerBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push('/order-food'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(statusIcon, color: bannerText, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'RECENT FOOD ORDER STATUS',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: bannerText, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: bannerBorder),
                                ),
                                child: Text(
                                  latestOrder.status.toUpperCase(),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: bannerText),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${latestOrder.foodItemName} (x${latestOrder.quantity})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                              ),
                              Text(
                                '₹${latestOrder.totalBill} • Pay on Delivery',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: bannerText),
                              ),
                            ],
                          ),
                          if (!isCancelled && !isDelivered) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Estimated Delivery: ${latestOrder.estimatedDeliveryTime} (Room ${latestOrder.roomNo})',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                            ),
                          ],
                          if (isCancelled && latestOrder.cancellationReason.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.red, size: 13),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Cancellation Reason: ${latestOrder.cancellationReason}',
                                      style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }(),

            // 6. COMPLAINT TRACKER BANNER
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200, width: 0.8),
                  ),
                  child: const Icon(Icons.feedback_outlined, color: Colors.orange, size: 20),
                ),
                title: const Row(
                  children: [
                    Text('Food Quality Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(width: 8),
                    Badge(
                      label: Text('In Progress', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.orange,
                    ),
                  ],
                ),
                subtitle: const Text('Complaint #1023 • Manager reviewed 2h ago', style: TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                onTap: () => context.push('/complaints'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 1.5 LIVE BROADCAST CARD (REAL-TIME SYNC FROM MESS MANAGER - DISMISS / READ ON TAP)
  Widget _buildLiveBroadcastCard(BuildContext context, NotificationModel notif, WidgetRef ref) {
    final timeStr = DateFormat('hh:mm a').format(notif.createdAt);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFF3E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(notificationsListProvider.notifier).markAsRead(notif.id);
            context.push('/notifications');
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE65100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.campaign, color: Colors.white, size: 13),
                              SizedBox(width: 4),
                              Text(
                                'NEW ANNOUNCEMENT',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            ref.read(notificationsListProvider.notifier).clearNotification(notif.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade300, width: 0.8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.close, size: 12, color: Color(0xFFE65100)),
                                SizedBox(width: 2),
                                Text('Dismiss', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notif.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF2E1500)),
                ),
                if (notif.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: TextStyle(fontSize: 12, color: Colors.brown.shade800, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. TOP PROFILE & DAY BANNER (HOSTEL NUMBER 4 - REAL STUDENT DATA)
  Widget _buildProfileBanner(BuildContext context, MenuItemData todayMenu, String dateString, H4Student student) {
    final initials = student.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

    return InkWell(
      onTap: () => context.push('/profile'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E5D2A), Color(0xFF2E7D32), Color(0xFF246C30)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF81C784).withOpacity(0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.20),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Day Indicator Pill
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white30, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wb_sunny_outlined, size: 13, color: Colors.amberAccent),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${todayMenu.dayHindi.toUpperCase()} • ${todayMenu.dayEnglish.toUpperCase()}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Profile, Email & Password Action Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mark_email_read_outlined, size: 14, color: Color(0xFF1B5E20)),
                      SizedBox(width: 4),
                      Text(
                        'Profile & Email ➔',
                        style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${student.name} 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reg: ${student.registrationNo} • Room ${student.roomNo} (${student.branch})',
                        style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Hostel 4 • $dateString',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_reset, size: 13, color: Colors.greenAccent),
                      SizedBox(width: 3),
                      Text(
                        'Change Password',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. TODAY'S MEALS ROW WITH DISHES, PRICES AND REAL SCAN ATTENDANCE STATUS
  Widget _buildDailyScheduleRow(WidgetRef ref, MenuItemData todayMenu, DateTime now) {
    final student = ref.watch(currentStudentProvider);
    final allScans = ref.watch(liveAttendanceProvider);

    bool isScanMatch(H4MealScanRecord s, String type) {
      final isStudent = s.registrationNo.trim() == student.registrationNo.trim() ||
          s.rollNo.trim() == student.rollNo.trim() ||
          (s.studentName.trim().isNotEmpty && s.studentName.trim().toLowerCase() == student.name.trim().toLowerCase());
      final dt = s.scannedAt.toLocal();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final mealClean = s.mealType.toLowerCase().trim();
      final isType = mealClean.contains(type.toLowerCase().trim());
      return isStudent && isToday && isType;
    }

    // Verify if student actually scanned for today's meals
    final isBkScanned = allScans.any((s) => isScanMatch(s, 'breakfast'));
    final isLunchScanned = allScans.any((s) => isScanMatch(s, 'lunch'));
    final isDinnerScanned = allScans.any((s) => isScanMatch(s, 'dinner'));

    final currentMinutes = now.hour * 60 + now.minute;
    const bkStart = 7 * 60 + 30;
    const bkEnd = 9 * 60 + 30;
    const lunchStart = 12 * 60 + 30;
    const lunchEnd = 14 * 60 + 30;
    const dinnerStart = 19 * 60 + 30;
    const dinnerEnd = 21 * 60 + 30;

    final ratingService = ref.watch(mealRatingServiceProvider);
    final bkRating = ratingService.getRating(todayMenu.dayEnglish, 'breakfast');
    final lunchRating = ratingService.getRating(todayMenu.dayEnglish, 'lunch');
    final dinnerRating = ratingService.getRating(todayMenu.dayEnglish, 'dinner');

    // 1. Breakfast status calculation
    String bkStatus;
    IconData bkStatusIcon;
    Color bkStatusColor;
    if (!todayMenu.breakfast.isAvailable) {
      bkStatus = 'Closed';
      bkStatusIcon = Icons.block;
      bkStatusColor = Colors.grey.shade600;
    } else if (isBkScanned) {
      bkStatus = 'Taken ✅';
      bkStatusIcon = Icons.check_circle;
      bkStatusColor = const Color(0xFF1B5E20);
    } else if (currentMinutes > bkEnd) {
      bkStatus = 'Not Taken ❌';
      bkStatusIcon = Icons.cancel_outlined;
      bkStatusColor = Colors.red.shade700;
    } else if (currentMinutes >= bkStart && currentMinutes <= bkEnd) {
      bkStatus = 'Serving Now';
      bkStatusIcon = Icons.restaurant;
      bkStatusColor = const Color(0xFF1565C0);
    } else {
      bkStatus = 'Upcoming';
      bkStatusIcon = Icons.schedule;
      bkStatusColor = Colors.grey.shade700;
    }

    // 2. Lunch status calculation
    String lunchStatus;
    IconData lunchStatusIcon;
    Color lunchStatusColor;
    if (isLunchScanned) {
      lunchStatus = 'Taken ✅';
      lunchStatusIcon = Icons.check_circle;
      lunchStatusColor = const Color(0xFF1B5E20);
    } else if (currentMinutes > lunchEnd) {
      lunchStatus = 'Not Taken ❌';
      lunchStatusIcon = Icons.cancel_outlined;
      lunchStatusColor = Colors.red.shade700;
    } else if (currentMinutes >= lunchStart && currentMinutes <= lunchEnd) {
      lunchStatus = 'Serving Now';
      lunchStatusIcon = Icons.restaurant;
      lunchStatusColor = const Color(0xFF1565C0);
    } else {
      lunchStatus = 'Upcoming';
      lunchStatusIcon = Icons.schedule;
      lunchStatusColor = Colors.grey.shade700;
    }

    // 3. Dinner status calculation
    String dinnerStatus;
    IconData dinnerStatusIcon;
    Color dinnerStatusColor;
    if (isDinnerScanned) {
      dinnerStatus = 'Taken ✅';
      dinnerStatusIcon = Icons.check_circle;
      dinnerStatusColor = const Color(0xFF1B5E20);
    } else if (currentMinutes > dinnerEnd) {
      dinnerStatus = 'Not Taken ❌';
      dinnerStatusIcon = Icons.cancel_outlined;
      dinnerStatusColor = Colors.red.shade700;
    } else if (currentMinutes >= dinnerStart && currentMinutes <= dinnerEnd) {
      dinnerStatus = 'Serving Now';
      dinnerStatusIcon = Icons.restaurant;
      dinnerStatusColor = const Color(0xFF1565C0);
    } else {
      dinnerStatus = 'Upcoming';
      dinnerStatusIcon = Icons.schedule;
      dinnerStatusColor = Colors.grey.shade700;
    }

    return Row(
      children: [
        // Breakfast Pill
        _mealSchedulePill(
          mealName: 'नाश्ता (Breakfast)',
          priceText: todayMenu.breakfast.isAvailable ? '₹${todayMenu.breakfast.price}' : 'CLOSED',
          itemsText: todayMenu.breakfast.isAvailable ? todayMenu.breakfast.itemsHindi : 'No Breakfast',
          status: bkStatus,
          statusIcon: bkStatusIcon,
          statusColor: bkStatusColor,
          rating: todayMenu.breakfast.isAvailable ? bkRating.rating : null,
          badge: todayMenu.breakfast.isAvailable ? bkRating.sentimentBadge : null,
          themeColor: const Color(0xFFE65100),
          bgColor: const Color(0xFFFFF8E1),
          borderColor: const Color(0xFFFFD54F),
          icon: Icons.breakfast_dining,
        ),
        const SizedBox(width: 8),

        // Lunch Pill
        _mealSchedulePill(
          mealName: 'दोपहर (Lunch)',
          priceText: '₹${todayMenu.lunch.price}',
          itemsText: todayMenu.lunch.itemsHindi,
          status: lunchStatus,
          statusIcon: lunchStatusIcon,
          statusColor: lunchStatusColor,
          rating: lunchRating.rating,
          badge: lunchRating.sentimentBadge,
          themeColor: const Color(0xFF1565C0),
          bgColor: const Color(0xFFE3F2FD),
          borderColor: const Color(0xFF90CAF9),
          icon: Icons.wb_sunny_outlined,
          highlight: todayMenu.lunch.price == 100,
        ),
        const SizedBox(width: 8),

        // Dinner Pill
        _mealSchedulePill(
          mealName: 'रात (Dinner)',
          priceText: '₹${todayMenu.dinner.price}',
          itemsText: todayMenu.dinner.itemsHindi,
          status: dinnerStatus,
          statusIcon: dinnerStatusIcon,
          statusColor: dinnerStatusColor,
          rating: dinnerRating.rating,
          badge: dinnerRating.sentimentBadge,
          themeColor: const Color(0xFF6A1B9A),
          bgColor: const Color(0xFFF3E5F5),
          borderColor: const Color(0xFFCE93D8),
          icon: Icons.nights_stay_outlined,
          highlight: todayMenu.dinner.price == 100,
        ),
      ],
    );
  }

  Widget _mealSchedulePill({
    required String mealName,
    required String priceText,
    required String itemsText,
    required String status,
    required IconData statusIcon,
    required Color statusColor,
    required Color themeColor,
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
    double? rating,
    String? badge,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 15, color: themeColor),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: highlight ? Colors.amber.shade400 : themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priceText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: highlight ? Colors.black87 : themeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              mealName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: themeColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              itemsText,
              style: const TextStyle(fontSize: 9.5, color: Colors.black87, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (rating != null && rating > 0) ...[
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: rating >= 4.5 ? Colors.green.shade800 : (rating >= 4.0 ? Colors.green.shade700 : Colors.amber.shade800),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 9, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            '$rating / 5',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      badge ?? '',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: themeColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon,
                    size: 11,
                    color: statusColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. ACTIVE / NEXT MEAL HERO CARD (DYNAMICAL TRANSITIONS UPON SCANNING)
  Widget _buildActiveMealCard(
    BuildContext context,
    WidgetRef ref,
    MenuItemData todayMenu,
    MenuItemData tomorrowMenu,
    DateTime now,
  ) {
    final student = ref.watch(currentStudentProvider);
    final allScans = ref.watch(liveAttendanceProvider);

    bool isScanMatch(H4MealScanRecord s, String type) {
      final isStudent = s.registrationNo.trim() == student.registrationNo.trim() ||
          s.rollNo.trim() == student.rollNo.trim() ||
          (s.studentName.trim().isNotEmpty && s.studentName.trim().toLowerCase() == student.name.trim().toLowerCase());
      final dt = s.scannedAt.toLocal();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final mealClean = s.mealType.toLowerCase().trim();
      return isStudent && isToday && mealClean.contains(type.toLowerCase().trim());
    }

    final isBkScanned = allScans.any((s) => isScanMatch(s, 'breakfast'));
    final isLunchScanned = allScans.any((s) => isScanMatch(s, 'lunch'));
    final isDinnerScanned = allScans.any((s) => isScanMatch(s, 'dinner'));

    final currentMinutes = now.hour * 60 + now.minute;
    const bkEnd = 9 * 60 + 30;    // 09:30 AM
    const lunchEnd = 14 * 60 + 30; // 02:30 PM
    const dinnerEnd = 21 * 60 + 30; // 09:30 PM

    // Resolve which meal to display as active or upcoming
    MealSlot displayMeal;
    String statusTitle;
    String dayLabel;
    String? previousMealCompletedMsg;
    bool isTomorrowMeal = false;
    bool isCurrentMealTaken = false;

    if (currentMinutes < bkEnd) {
      // Morning
      if (isBkScanned || !todayMenu.breakfast.isAvailable) {
        displayMeal = todayMenu.lunch;
        statusTitle = 'UPCOMING MEAL (TODAY)';
        dayLabel = todayMenu.dayHindi;
        previousMealCompletedMsg = isBkScanned ? 'Breakfast Scanned & Eaten ✅' : 'No Breakfast on Sunday';
      } else {
        displayMeal = todayMenu.breakfast;
        statusTitle = 'BREAKFAST (TODAY)';
        dayLabel = todayMenu.dayHindi;
      }
    } else if (currentMinutes < lunchEnd) {
      // Afternoon
      if (isLunchScanned) {
        displayMeal = todayMenu.dinner;
        statusTitle = 'UPCOMING MEAL (TODAY)';
        dayLabel = todayMenu.dayHindi;
        previousMealCompletedMsg = 'Lunch Scanned & Eaten ✅';
      } else {
        displayMeal = todayMenu.lunch;
        statusTitle = 'LUNCH (TODAY)';
        dayLabel = todayMenu.dayHindi;
      }
    } else if (currentMinutes < dinnerEnd) {
      // Evening / Dinner
      if (isDinnerScanned) {
        isCurrentMealTaken = true;
        isTomorrowMeal = true;
        displayMeal = tomorrowMenu.breakfast.isAvailable ? tomorrowMenu.breakfast : tomorrowMenu.lunch;
        statusTitle = 'TOMORROW UPCOMING';
        dayLabel = tomorrowMenu.dayHindi;
        previousMealCompletedMsg = '🎉 Tonight\'s Dinner Scanned & Verified ✅';
      } else {
        displayMeal = todayMenu.dinner;
        statusTitle = 'DINNER (TODAY)';
        dayLabel = todayMenu.dayHindi;
      }
    } else {
      // Night after 9:30 PM
      isTomorrowMeal = true;
      displayMeal = tomorrowMenu.breakfast.isAvailable ? tomorrowMenu.breakfast : tomorrowMenu.lunch;
      statusTitle = 'TOMORROW UPCOMING';
      dayLabel = tomorrowMenu.dayHindi;
      previousMealCompletedMsg = isDinnerScanned ? 'Tonight\'s Dinner Eaten ✅' : 'All Meals Completed for Today';
    }

    final isSpecial = displayMeal.price == 100;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSpecial
              ? [const Color(0xFFFFE0B2), const Color(0xFFFFCC80), const Color(0xFFFFB74D)]
              : [
                  const Color(0xFF1B5E20).withValues(alpha: 0.37),
                  const Color(0xFF2E7D32).withValues(alpha: 0.37),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSpecial ? const Color(0xFFFFA726) : const Color(0xFF2E7D32).withValues(alpha: 0.55),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSpecial ? Colors.orange : const Color(0xFF1B5E20)).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // If previous meal was taken, show prominent banner
          if (previousMealCompletedMsg != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      previousMealCompletedMsg,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                    ),
                  ),
                  if (isCurrentMealTaken)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ENJOY MEAL', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ],

          // Meal Header Pill & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSpecial ? const Color(0xFFFFB74D) : const Color(0xFF81C784)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isTomorrowMeal ? Icons.wb_twilight : Icons.restaurant,
                      color: isSpecial ? const Color(0xFFE65100) : const Color(0xFF1B5E20),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isTomorrowMeal
                          ? 'TOMORROW • ${displayMeal.nameEnglish.toUpperCase()}'
                          : '${dayLabel.toUpperCase()} ${displayMeal.nameEnglish.toUpperCase()}',
                      style: TextStyle(
                        color: isSpecial ? const Color(0xFFE65100) : const Color(0xFF1B5E20),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSpecial ? const Color(0xFFE65100) : const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${displayMeal.price} / plate',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayMeal.itemsHindi,
            style: const TextStyle(color: Color(0xFF0F3818), fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            displayMeal.itemsEnglish,
            style: const TextStyle(color: Color(0xFF2E5B35), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // SECONDARY WHITE BOX: Mess-Off Deadline Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Color(0xFFE65100), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTomorrowMeal
                        ? 'Mess-Off Cutoff: ${displayMeal.cutoffTime} tomorrow morning (Strict)'
                        : 'Mess-Off Deadline: ${displayMeal.cutoffTime} (Strict Enforcement)',
                    style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ACTION BUTTONS ROW
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.event_busy, size: 18),
                  label: Text(
                    isTomorrowMeal ? 'ADVANCE MESS-OFF' : 'MARK MESS-OFF',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => context.push('/mess-off'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('SCAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => context.push('/scanner'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. COLORFUL QUICK ACTIONS GRID
  Widget _buildColorfulQuickActionsGrid(BuildContext context) {
    final actions = [
      _ActionItem(
        title: 'QR Attendance',
        subtitle: 'Scan to issue meal',
        icon: Icons.qr_code_scanner,
        startColor: const Color(0xFFE8F5E9),
        endColor: const Color(0xFFC8E6C9),
        borderColor: const Color(0xFFA5D6A7),
        iconColor: const Color(0xFF2E7D32),
        route: '/scanner',
      ),
      _ActionItem(
        title: 'Advance Mess-Off',
        subtitle: 'Future date opt-out',
        icon: Icons.event_busy,
        startColor: const Color(0xFFFFEBEE),
        endColor: const Color(0xFFFFCDD2),
        borderColor: const Color(0xFFEF9A9A),
        iconColor: const Color(0xFFC62828),
        route: '/mess-off',
      ),
      _ActionItem(
        title: 'Weekly Menu',
        subtitle: '7-day master timetable',
        icon: Icons.menu_book,
        startColor: const Color(0xFFF3E5F5),
        endColor: const Color(0xFFE1BEE7),
        borderColor: const Color(0xFFCE93D8),
        iconColor: const Color(0xFF6A1B9A),
        onTap: () => _showWeeklyMenuModal(context),
      ),
      _ActionItem(
        title: 'Mess Bills',
        subtitle: 'Fee & rebate history',
        icon: Icons.receipt_long,
        startColor: const Color(0xFFFFF3E0),
        endColor: const Color(0xFFFFE0B2),
        borderColor: const Color(0xFFFFCC80),
        iconColor: const Color(0xFFE65100),
        route: '/bill',
      ),
      _ActionItem(
        title: 'Campus Events',
        subtitle: 'College calendar & fests',
        icon: Icons.celebration,
        startColor: const Color(0xFFE8EAF6),
        endColor: const Color(0xFFC5CAE9),
        borderColor: const Color(0xFF9FA8DA),
        iconColor: const Color(0xFF283593),
        route: '/events',
      ),
      _ActionItem(
        title: 'Complaints',
        subtitle: 'Report food issues',
        icon: Icons.chat_bubble_outline,
        startColor: const Color(0xFFE3F2FD),
        endColor: const Color(0xFFBBDEFB),
        borderColor: const Color(0xFF90CAF9),
        iconColor: const Color(0xFF1565C0),
        route: '/complaints',
      ),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final double aspectRatio = screenWidth < 360 ? 1.75 : (screenWidth < 400 ? 1.92 : 2.15);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 600 ? 3 : 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: aspectRatio,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return InkWell(
          onTap: item.onTap ?? () => context.push(item.route!),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.startColor, item.endColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: item.iconColor.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: item.iconColor.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: item.iconColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 5. COLORFUL SUMMARY CARD
  Widget _colorfulSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color startColor,
    required Color endColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: textColor.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.8))),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // 6. BOTTOM SHEET WEEKLY MASTER MENU MODAL WITH ML RATINGS
  void _showWeeklyMenuModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final ratingService = ref.watch(mealRatingServiceProvider);

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Weekly Meal Menu & ML Ratings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                            Text('Dynamic AI crowd popularity ratings (out of 5) per meal', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: WeeklyMenuData.schedule.length,
                      itemBuilder: (context, index) {
                        final day = WeeklyMenuData.schedule[index];
                        final bkRating = ratingService.getRating(day.dayEnglish, 'breakfast');
                        final lunchRating = ratingService.getRating(day.dayEnglish, 'lunch');
                        final dinnerRating = ratingService.getRating(day.dayEnglish, 'dinner');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBF9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${day.dayHindi} (${day.dayEnglish})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Text(
                                      'Day ${index + 1}',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              _menuSlotRow(
                                title: '🌅 Breakfast (7 AM)',
                                items: day.breakfast.itemsHindi,
                                price: day.breakfast.price,
                                isAvailable: day.breakfast.isAvailable,
                                ratingInfo: day.breakfast.isAvailable ? bkRating : null,
                              ),
                              const SizedBox(height: 8),
                              _menuSlotRow(
                                title: '☀️ Lunch (11 AM)',
                                items: day.lunch.itemsHindi,
                                price: day.lunch.price,
                                isAvailable: true,
                                ratingInfo: lunchRating,
                              ),
                              const SizedBox(height: 8),
                              _menuSlotRow(
                                title: '🌙 Dinner (6 PM)',
                                items: day.dinner.itemsHindi,
                                price: day.dinner.price,
                                isAvailable: true,
                                ratingInfo: dinnerRating,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _menuSlotRow({
    required String title,
    required String items,
    required int price,
    required bool isAvailable,
    MealRatingInfo? ratingInfo,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
              if (ratingInfo != null && ratingInfo.rating > 0) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: ratingInfo.rating >= 4.5 ? Colors.green.shade800 : (ratingInfo.rating >= 4.0 ? Colors.green.shade700 : Colors.amber.shade800),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 9, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            '${ratingInfo.rating} ★',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAvailable ? items : 'No Breakfast (Mess Closed)',
                style: TextStyle(fontSize: 11.5, color: isAvailable ? Colors.grey.shade800 : Colors.grey, fontWeight: FontWeight.w500),
              ),
              if (ratingInfo != null && ratingInfo.rating > 0) ...[
                const SizedBox(height: 1),
                Text(
                  '${ratingInfo.sentimentBadge} • Crowd ~${ratingInfo.totalScans} (${ratingInfo.crowdTurnoutPercentage}%)',
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: price == 100 ? Colors.orange.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: price == 100 ? Colors.orange.shade300 : Colors.grey.shade300, width: 0.6),
          ),
          child: Text(
            isAvailable ? '₹$price' : 'CLOSED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: price == 100 ? Colors.orange.shade900 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final Color borderColor;
  final Color iconColor;
  final String? route;
  final VoidCallback? onTap;

  _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.borderColor,
    required this.iconColor,
    this.route,
    this.onTap,
  });
}
