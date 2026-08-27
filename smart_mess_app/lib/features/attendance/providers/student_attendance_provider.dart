import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'attendance_provider.dart';
import '../../../core/router/app_router.dart';

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
  final student = ref.watch(currentStudentProvider);
  final allScans = ref.watch(liveAttendanceProvider);
  final studentScans = allScans.where((s) => s.registrationNo == student.registrationNo).toList();

  final mealsEaten = studentScans.length;
  final mealsSkipped = 0; // Dynamic from actual messOffs
  final totalSavings = mealsSkipped * 50;
  final totalServed = mealsEaten + mealsSkipped;
  final attendanceRate = totalServed > 0 ? (mealsEaten / totalServed) * 100 : 100.0;

  // Group scans by date
  final Map<String, List<H4MealScanRecord>> scansByDate = {};
  for (final scan in studentScans) {
    final dateKey = DateFormat('yyyy-MM-dd').format(scan.scannedAt);
    scansByDate.putIfAbsent(dateKey, () => []).add(scan);
  }

  final List<DailyMealRecord> dailyRecords = [];
  scansByDate.forEach((dateKey, dayScans) {
    final date = DateTime.tryParse(dateKey) ?? DateTime.now();
    H4MealScanRecord? bScan;
    H4MealScanRecord? lScan;
    H4MealScanRecord? dScan;

    for (final s in dayScans) {
      if (s.mealType.toLowerCase().contains('breakfast')) bScan = s;
      if (s.mealType.toLowerCase().contains('lunch')) lScan = s;
      if (s.mealType.toLowerCase().contains('dinner')) dScan = s;
    }

    dailyRecords.add(DailyMealRecord(
      dateString: DateFormat('dd MMM yyyy').format(date),
      dayName: DateFormat('EEEE, dd MMM').format(date),
      date: date,
      breakfast: bScan != null ? MealAttendanceStatus.eaten : MealAttendanceStatus.scheduled,
      breakfastTime: bScan != null ? DateFormat('hh:mm a').format(bScan.scannedAt) : null,
      lunch: lScan != null ? MealAttendanceStatus.eaten : MealAttendanceStatus.scheduled,
      lunchTime: lScan != null ? DateFormat('hh:mm a').format(lScan.scannedAt) : null,
      dinner: dScan != null ? MealAttendanceStatus.eaten : MealAttendanceStatus.scheduled,
      dinnerTime: dScan != null ? DateFormat('hh:mm a').format(dScan.scannedAt) : null,
    ));
  });

  dailyRecords.sort((a, b) => b.date.compareTo(a.date));

  return StudentAttendanceStats(
    totalMealsServed: totalServed,
    mealsEaten: mealsEaten,
    mealsSkipped: mealsSkipped,
    totalSavings: totalSavings,
    attendancePercentage: attendanceRate,
    dailyRecords: dailyRecords,
  );
});
