import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/student_attendance_provider.dart';

class MealHistoryScreen extends ConsumerStatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  ConsumerState<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends ConsumerState<MealHistoryScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(studentAttendanceStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: const Text('My Meal Attendance History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Monthly Summary Banner
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E5D2A), Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E20).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.fact_check, color: Colors.amberAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'August 2026 Dining Record',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Text(
                        '${stats.attendancePercentage.toStringAsFixed(0)}% Turnout',
                        style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3-Metric Stats Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${stats.mealsEaten}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                            ),
                            const SizedBox(height: 2),
                            const Text('Meals Eaten ✅', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${stats.mealsSkipped}',
                              style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 20),
                            ),
                            const SizedBox(height: 2),
                            const Text('Skipped (Off) ⏭️', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '₹${stats.totalSavings}',
                              style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.w900, fontSize: 20),
                            ),
                            const SizedBox(height: 2),
                            const Text('Rebate Saved 💰', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Title
          const Row(
            children: [
              Icon(Icons.calendar_month, color: Color(0xFF1B5E20), size: 18),
              SizedBox(width: 6),
              Text(
                'DAILY MEAL CONSUMPTION LOG',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1B5E20), letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Daily Records List
          ...stats.dailyRecords.map((rec) => _buildDayRecordCard(rec)),
        ],
      ),
    );
  }

  Widget _buildDayRecordCard(DailyMealRecord rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rec.dayName,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${rec.eatenCount}/3 Eaten',
                  style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3 Meals Row
          Row(
            children: [
              Expanded(child: _mealChip('Breakfast', rec.breakfast, rec.breakfastTime)),
              const SizedBox(width: 8),
              Expanded(child: _mealChip('Lunch', rec.lunch, rec.lunchTime)),
              const SizedBox(width: 8),
              Expanded(child: _mealChip('Dinner', rec.dinner, rec.dinnerTime)),
            ],
          ),

          if (rec.note != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFFE65100)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rec.note!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mealChip(String title, MealAttendanceStatus status, String? time) {
    Color bg;
    Color border;
    Color textCol;
    String statusText;
    IconData icon;

    switch (status) {
      case MealAttendanceStatus.eaten:
        bg = const Color(0xFFE8F5E9);
        border = const Color(0xFFA5D6A7);
        textCol = const Color(0xFF1B5E20);
        statusText = 'EATEN';
        icon = Icons.check_circle;
        break;
      case MealAttendanceStatus.skipped:
        bg = const Color(0xFFFFF3E0);
        border = const Color(0xFFFFCC80);
        textCol = const Color(0xFFE65100);
        statusText = 'SKIPPED';
        icon = Icons.cancel_outlined;
        break;
      case MealAttendanceStatus.scheduled:
        bg = const Color(0xFFF5F5F5);
        border = const Color(0xFFE0E0E0);
        textCol = Colors.grey.shade700;
        statusText = 'SCHEDULED';
        icon = Icons.access_time;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: textCol),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textCol),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: textCol),
          ),
          if (time != null) ...[
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(fontSize: 9, color: textCol.withOpacity(0.85)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
