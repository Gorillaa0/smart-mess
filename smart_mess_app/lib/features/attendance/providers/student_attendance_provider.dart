import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum MealAttendanceStatus {
  eaten,
  skipped,
  scheduled,
}

class DailyMealRecord {
  final String dateString;
  final String dayName;
  final DateTime date;
  final MealAttendanceStatus breakfast;
  final String? breakfastTime;
  final MealAttendanceStatus lunch;
  final String? lunchTime;
  final MealAttendanceStatus dinner;
  final String? dinnerTime;
  final String? note;

  const DailyMealRecord({
    required this.dateString,
    required this.dayName,
    required this.date,
    required this.breakfast,
    this.breakfastTime,
    required this.lunch,
    this.lunchTime,
    required this.dinner,
    this.dinnerTime,
    this.note,
  });

  int get eatenCount {
    int count = 0;
    if (breakfast == MealAttendanceStatus.eaten) count++;
    if (lunch == MealAttendanceStatus.eaten) count++;
    if (dinner == MealAttendanceStatus.eaten) count++;
    return count;
  }

  int get skippedCount {
    int count = 0;
    if (breakfast == MealAttendanceStatus.skipped) count++;
    if (lunch == MealAttendanceStatus.skipped) count++;
    if (dinner == MealAttendanceStatus.skipped) count++;
    return count;
  }
}

class StudentAttendanceStats {
  final int totalMealsServed;
  final int mealsEaten;
  final int mealsSkipped;
  final int totalSavings;
  final double attendancePercentage;
  final List<DailyMealRecord> dailyRecords;

  const StudentAttendanceStats({
    required this.totalMealsServed,
    required this.mealsEaten,
    required this.mealsSkipped,
    required this.totalSavings,
    required this.attendancePercentage,
    required this.dailyRecords,
  });
}

final studentAttendanceStatsProvider = Provider<StudentAttendanceStats>((ref) {
  final now = DateTime.now();

  // Generate realistic, consistent meal log for the student
  final records = [
    // Today
    DailyMealRecord(
      dateString: DateFormat('dd MMM yyyy').format(now),
      dayName: 'Today (${DateFormat('EEEE').format(now)})',
      date: now,
      breakfast: MealAttendanceStatus.eaten,
      breakfastTime: '08:22 AM',
      lunch: MealAttendanceStatus.eaten,
      lunchTime: '01:14 PM',
      dinner: MealAttendanceStatus.scheduled,
      dinnerTime: '07:30 PM - 09:30 PM',
      note: 'Dinner counter opens at 07:30 PM',
    ),
    // Yesterday
    DailyMealRecord(
      dateString: DateFormat('dd MMM yyyy').format(now.subtract(const Duration(days: 1))),
      dayName: 'Yesterday (${DateFormat('EEEE').format(now.subtract(const Duration(days: 1)))})',
      date: now.subtract(const Duration(days: 1)),
      breakfast: MealAttendanceStatus.eaten,
      breakfastTime: '08:35 AM',
      lunch: MealAttendanceStatus.skipped,
      lunchTime: 'Mess-Off Applied',
      dinner: MealAttendanceStatus.eaten,
      dinnerTime: '08:15 PM',
      note: 'Lunch Mess-Off: ₹50 rebate credited',
    ),
    // 2 Days Ago
    DailyMealRecord(
      dateString: DateFormat('dd MMM yyyy').format(now.subtract(const Duration(days: 2))),
      dayName: DateFormat('EEEE, dd MMM').format(now.subtract(const Duration(days: 2))),
      date: now.subtract(const Duration(days: 2)),
      breakfast: MealAttendanceStatus.eaten,
      breakfastTime: '08:10 AM',
      lunch: MealAttendanceStatus.eaten,
      lunchTime: '01:25 PM',
      dinner: MealAttendanceStatus.eaten,
      dinnerTime: '08:40 PM',
    ),
    // 3 Days Ago (Weekend)
    DailyMealRecord(
      dateString: DateFormat('dd MMM yyyy').format(now.subtract(const Duration(days: 3))),
      dayName: DateFormat('EEEE, dd MMM').format(now.subtract(const Duration(days: 3))),
      date: now.subtract(const Duration(days: 3)),
      breakfast: MealAttendanceStatus.skipped,
      breakfastTime: 'Mess-Off Applied',
      lunch: MealAttendanceStatus.skipped,
      lunchTime: 'Mess-Off Applied',
      dinner: MealAttendanceStatus.skipped,
      dinnerTime: 'Mess-Off Applied',
      note: 'Full Day Mess-Off (Weekend Leave) • ₹125 rebate',
    ),
    // 4 Days Ago
    DailyMealRecord(
      dateString: DateFormat('dd MMM yyyy').format(now.subtract(const Duration(days: 4))),
      dayName: DateFormat('EEEE, dd MMM').format(now.subtract(const Duration(days: 4))),
      date: now.subtract(const Duration(days: 4)),
      breakfast: MealAttendanceStatus.eaten,
      breakfastTime: '08:45 AM',
      lunch: MealAttendanceStatus.eaten,
      lunchTime: '01:05 PM',
      dinner: MealAttendanceStatus.eaten,
      dinnerTime: '08:10 PM',
    ),
    // 5 Days Ago
    DailyMealRecord(
      dateString: DateFormat('dd MMM yyyy').format(now.subtract(const Duration(days: 5))),
      dayName: DateFormat('EEEE, dd MMM').format(now.subtract(const Duration(days: 5))),
      date: now.subtract(const Duration(days: 5)),
      breakfast: MealAttendanceStatus.eaten,
      breakfastTime: '08:18 AM',
      lunch: MealAttendanceStatus.eaten,
      lunchTime: '01:30 PM',
      dinner: MealAttendanceStatus.skipped,
      dinnerTime: 'Mess-Off Applied',
      note: 'Dinner Mess-Off: ₹50 rebate credited',
    ),
    // 6 Days Ago
    DailyMealRecord(
      dateString: DateFormat('dd MMM yyyy').format(now.subtract(const Duration(days: 6))),
      dayName: DateFormat('EEEE, dd MMM').format(now.subtract(const Duration(days: 6))),
      date: now.subtract(const Duration(days: 6)),
      breakfast: MealAttendanceStatus.eaten,
      breakfastTime: '08:25 AM',
      lunch: MealAttendanceStatus.eaten,
      lunchTime: '01:10 PM',
      dinner: MealAttendanceStatus.eaten,
      dinnerTime: '08:50 PM',
    ),
  ];

  const totalMeals = 78;
  const eaten = 62;
  const skipped = 16;
  const savings = skipped * 50;
  final rate = (eaten / (eaten + skipped)) * 100;

  return StudentAttendanceStats(
    totalMealsServed: totalMeals,
    mealsEaten: eaten,
    mealsSkipped: skipped,
    totalSavings: savings,
    attendancePercentage: rate,
    dailyRecords: records,
  );
});
