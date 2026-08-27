import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/weekly_menu.dart';
import '../../../core/constants/h4_students_data.dart';
import '../../../core/models/notification_model.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../events/providers/events_provider.dart';
import '../../attendance/providers/student_attendance_provider.dart';

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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
              ),
              child: const Icon(Icons.restaurant_menu, color: Color(0xFF1B5E20), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Mess',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), fontSize: 17),
                ),
                Text(
                  'Central Dining Mess Hall',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View Profile & Password',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF81C784), width: 1),
              ),
              child: const Icon(Icons.person, color: Color(0xFF1B5E20), size: 18),
            ),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            tooltip: 'Announcements & Notifications',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
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
                    size: 18,
                  ),
                ),
                if (unreadNotifsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD32F2F),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$unreadNotifsCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade200, width: 0.8),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Color(0xFFE65100), size: 18),
            ),
            onPressed: () => context.push('/scanner'),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade200, width: 0.8),
              ),
              child: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            ),
            onPressed: () {
              ref.read(authStateProvider.notifier).state = false;
              context.go('/login');
            },
          ),
          const SizedBox(width: 6),
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
            const SizedBox(height: 18),

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

            _buildDailyScheduleRow(todayMenu, now),
            const SizedBox(height: 18),

            // 3. ACTIVE / NEXT MEAL HERO CARD
            _buildActiveMealCard(context, activeState, todayMenu),
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

            // 5. BILLING & MEAL ATTENDANCE SUMMARY CARDS
            Row(
              children: [
                Expanded(
                  child: _colorfulSummaryCard(
                    context,
                    title: 'Current Mess Bill',
                    value: '₹2,450',
                    subtitle: 'Aug 2026 • ${attStats.mealsEaten} meals eaten',
                    icon: Icons.receipt_long,
                    startColor: const Color(0xFFFFF8E1),
                    endColor: const Color(0xFFFFECB3),
                    borderColor: const Color(0xFFFFD54F),
                    textColor: const Color(0xFFE65100),
                    onTap: () => context.push('/bill'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _colorfulSummaryCard(
                    context,
                    title: 'Meal Attendance',
                    value: '${attStats.mealsEaten}/${attStats.mealsEaten + attStats.mealsSkipped} Eaten',
                    subtitle: '${attStats.attendancePercentage.toStringAsFixed(0)}% Turnout • ${attStats.mealsSkipped} Skipped',
                    icon: Icons.fact_check_rounded,
                    startColor: const Color(0xFFE8F5E9),
                    endColor: const Color(0xFFC8E6C9),
                    borderColor: const Color(0xFFA5D6A7),
                    textColor: const Color(0xFF1B5E20),
                    onTap: () => context.push('/meal-history'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 5.5 LIVE MEAL ATTENDANCE TIMELINE (MEALS EATEN VS SKIPPED BREAKDOWN)
            _buildLiveAttendanceTimelineCard(context, attStats),
            const SizedBox(height: 16),

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

  // 1.5 LIVE BROADCAST CARD (REAL-TIME SYNC FROM MESS MANAGER)
  Widget _buildLiveBroadcastCard(BuildContext context, NotificationModel notif) {
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
            color: Colors.orange.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/notifications'),
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
                                'LIVE ANNOUNCEMENT',
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
                    const Row(
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFE65100)),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white30, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 13, color: Colors.amberAccent),
                      const SizedBox(width: 5),
                      Text(
                        '${todayMenu.dayHindi.toUpperCase()} • ${todayMenu.dayEnglish.toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                // Profile & Password Action Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.manage_accounts, size: 14, color: Color(0xFF1B5E20)),
                      SizedBox(width: 4),
                      Text(
                        'Profile & Password ➔',
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hostel Number 4 • $dateString',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const Text(
                    'Tap to Change Password',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. TODAY'S MEALS ROW WITH DISHES AND PRICES
  Widget _buildDailyScheduleRow(MenuItemData todayMenu, DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;
    final isBreakfastPassed = currentMinutes >= 9 * 60 + 30;
    final isLunchPassed = currentMinutes >= 14 * 60 + 30;

    return Row(
      children: [
        // Breakfast Pill
        _mealSchedulePill(
          mealName: 'नाश्ता (Breakfast)',
          priceText: todayMenu.breakfast.isAvailable ? '₹${todayMenu.breakfast.price}' : 'CLOSED',
          itemsText: todayMenu.breakfast.isAvailable ? todayMenu.breakfast.itemsHindi : 'No Breakfast',
          status: isBreakfastPassed ? 'Taken' : (todayMenu.breakfast.isAvailable ? 'Upcoming' : 'Closed'),
          isPassed: isBreakfastPassed,
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
          status: isLunchPassed ? 'Taken' : (isBreakfastPassed ? 'Serving Now' : 'Upcoming'),
          isPassed: isLunchPassed,
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
          status: 'Upcoming',
          isPassed: false,
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
    required bool isPassed,
    required Color themeColor,
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.05),
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
                Icon(icon, size: 16, color: themeColor),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: highlight ? Colors.amber.shade400 : themeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priceText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: highlight ? Colors.black87 : themeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              mealName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: themeColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              itemsText,
              style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  isPassed ? Icons.check_circle : Icons.schedule,
                  size: 11,
                  color: isPassed ? Colors.green : Colors.grey.shade600,
                ),
                const SizedBox(width: 3),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? Colors.green.shade800 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. ACTIVE / NEXT MEAL HERO CARD
  Widget _buildActiveMealCard(BuildContext context, ActiveMealStatus activeState, MenuItemData todayMenu) {
    if (activeState.isClosedForToday) {
      final tomorrowBreakfast = activeState.nextMealTomorrow;
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF165024), Color(0xFF226730), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF81C784).withOpacity(0.45),
            width: 1.2,
          ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white30, width: 0.8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.nightlight_round, color: Colors.amberAccent, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'MESS CLOSED FOR TODAY',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.4),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.shade400.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.greenAccent.shade400, width: 0.8),
                  ),
                  child: const Text(
                    'All Meals Served',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Tonight\'s dinner is complete. Kitchen service will resume tomorrow morning at Hostel H4.',
              style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.3),
            ),
            const SizedBox(height: 12),
            if (tomorrowBreakfast != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.wb_sunny_outlined, size: 13, color: Colors.amberAccent),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  "TOMORROW'S BREAKFAST",
                                  style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '₹${tomorrowBreakfast.price} • ${tomorrowBreakfast.servingTime}',
                            style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tomorrowBreakfast.itemsHindi,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tomorrowBreakfast.itemsEnglish,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Cutoff: ${tomorrowBreakfast.cutoffTime} tomorrow',
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 10.5, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => context.push('/mess-off'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OPT OUT',
                              style: TextStyle(color: Color(0xFF1B5E20), fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final meal = activeState.meal!;
    final isSpecial = meal.price == 100;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSpecial
              ? [const Color(0xFFFFE0B2), const Color(0xFFFFCC80), const Color(0xFFFFB74D)]
              : [const Color(0xFFD0EBD2), const Color(0xFFB8E2BC), const Color(0xFFA2D7A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSpecial ? const Color(0xFFFFA726) : const Color(0xFF66BB6A),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSpecial ? Colors.orange : const Color(0xFF2E7D32)).withOpacity(0.15),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSpecial ? const Color(0xFFFFB74D) : const Color(0xFF81C784)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.restaurant, color: isSpecial ? const Color(0xFFE65100) : const Color(0xFF1B5E20), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${activeState.dayName.toUpperCase()} ${meal.nameEnglish.toUpperCase()}',
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
                  '₹${meal.price} / plate',
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
            meal.itemsHindi,
            style: const TextStyle(color: Color(0xFF0F3818), fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            meal.itemsEnglish,
            style: const TextStyle(color: Color(0xFF2E5B35), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
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
                    'Mess-Off Deadline: ${meal.cutoffTime} (Strict Enforcement)',
                    style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
                  label: const Text('MARK MESS-OFF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => context.push('/mess-off'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        title: 'Mess Bills & Log',
        subtitle: 'Monthly attendance tally',
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return InkWell(
          onTap: item.onTap ?? () => context.push(item.route!),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textColor)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // 6. BOTTOM SHEET WEEKLY MASTER MENU MODAL
  void _showWeeklyMenuModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                        Text('Weekly Mess Timetable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                        Text('Central Dining Facility • Regular Menu', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                          _menuSlotRow('🌅 Breakfast (7 AM)', day.breakfast.itemsHindi, day.breakfast.price, day.breakfast.isAvailable),
                          const SizedBox(height: 6),
                          _menuSlotRow('☀️ï¸ Lunch (11 AM)', day.lunch.itemsHindi, day.lunch.price, true),
                          const SizedBox(height: 6),
                          _menuSlotRow('🌙 Dinner (6 PM)', day.dinner.itemsHindi, day.dinner.price, true),
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
  }

  Widget _menuSlotRow(String title, String items, int price, bool isAvailable) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        Expanded(
          child: Text(
            isAvailable ? items : 'No Breakfast (Mess Closed)',
            style: TextStyle(fontSize: 11.5, color: isAvailable ? Colors.grey.shade800 : Colors.grey),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: price == 100 ? Colors.orange.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
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

  Widget _buildLiveAttendanceTimelineCard(BuildContext context, StudentAttendanceStats attStats) {
    final recentRecords = attStats.dailyRecords.take(2).toList(); // Today & Yesterday

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                    child: const Icon(Icons.fact_check, color: Color(0xFF1B5E20), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MY MEAL ATTENDANCE LOG',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF1B5E20),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/meal-history'),
                child: const Row(
                  children: [
                    Text(
                      'View All Log',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Monthly summary badge row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '✅ ${attStats.mealsEaten} Eaten',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF1B5E20)),
                ),
                Text(
                  '⏭️ ${attStats.mealsSkipped} Skipped (Mess-Off)',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFFE65100)),
                ),
                Text(
                  '💰 ₹${attStats.totalSavings} Saved',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Day-by-day rows
          ...recentRecords.map((day) => Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        day.dayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.black87),
                      ),
                      Text(
                        '${day.eatenCount}/3 Meals Eaten',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: day.eatenCount > 0 ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildMealChipCompact('Breakfast', day.breakfast, day.breakfastTime)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildMealChipCompact('Lunch', day.lunch, day.lunchTime)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildMealChipCompact('Dinner', day.dinner, day.dinnerTime)),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMealChipCompact(String mealName, MealAttendanceStatus status, String? time) {
    Color bg;
    Color border;
    Color textCol;
    String label;
    IconData icon;

    switch (status) {
      case MealAttendanceStatus.eaten:
        bg = const Color(0xFFE8F5E9);
        border = const Color(0xFFA5D6A7);
        textCol = const Color(0xFF1B5E20);
        label = 'EATEN';
        icon = Icons.check_circle;
        break;
      case MealAttendanceStatus.skipped:
        bg = const Color(0xFFFFF3E0);
        border = const Color(0xFFFFCC80);
        textCol = const Color(0xFFE65100);
        label = 'SKIPPED';
        icon = Icons.cancel_outlined;
        break;
      case MealAttendanceStatus.scheduled:
        bg = const Color(0xFFEEEEEE);
        border = const Color(0xFFE0E0E0);
        textCol = Colors.grey.shade700;
        label = 'SCHEDULED';
        icon = Icons.access_time;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: textCol),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  mealName,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textCol),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: textCol),
          ),
        ],
      ),
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
