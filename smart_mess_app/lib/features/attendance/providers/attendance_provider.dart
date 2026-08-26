import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/h4_students_data.dart';
import '../../../core/models/attendance_model.dart';

class H4MealScanRecord {
  final String id;
  final String registrationNo;
  final String studentName;
  final String rollNo;
  final String branch;
  final String mealType;
  final DateTime scannedAt;
  final String roomNo;

  const H4MealScanRecord({
    required this.id,
    required this.registrationNo,
    required this.studentName,
    required this.rollNo,
    required this.branch,
    required this.mealType,
    required this.scannedAt,
    required this.roomNo,
  });

  AttendanceModel toAttendanceModel() {
    return AttendanceModel(
      id: id,
      studentId: registrationNo,
      mealId: mealType,
      scannedAt: scannedAt,
      status: 'present',
    );
  }
}

class AttendanceNotifier extends StateNotifier<List<H4MealScanRecord>> {
  AttendanceNotifier() : super([]);

  bool hasScanned(String registrationNo, String mealType) {
    final today = DateTime.now();
    return state.any((record) =>
        record.registrationNo == registrationNo &&
        record.mealType.toLowerCase() == mealType.toLowerCase() &&
        record.scannedAt.day == today.day &&
        record.scannedAt.month == today.month &&
        record.scannedAt.year == today.year);
  }

  bool recordScan(H4Student student, String mealType) {
    if (hasScanned(student.registrationNo, mealType)) {
      return false; // Already scanned
    }

    final newRecord = H4MealScanRecord(
      id: 'SCAN_${DateTime.now().millisecondsSinceEpoch}_${student.rollNo}',
      registrationNo: student.registrationNo,
      studentName: student.name,
      rollNo: student.rollNo,
      branch: student.branch,
      mealType: mealType,
      scannedAt: DateTime.now(),
      roomNo: student.roomNo,
    );

    state = [newRecord, ...state];
    return true;
  }

  List<H4MealScanRecord> getStudentHistory(String registrationNo) {
    return state.where((s) => s.registrationNo == registrationNo).toList();
  }

  int getTodayMealCount(String mealType) {
    final today = DateTime.now();
    return state
        .where((r) =>
            r.mealType.toLowerCase() == mealType.toLowerCase() &&
            r.scannedAt.day == today.day &&
            r.scannedAt.month == today.month &&
            r.scannedAt.year == today.year)
        .length;
  }
}

final liveAttendanceProvider = StateNotifierProvider<AttendanceNotifier, List<H4MealScanRecord>>((ref) {
  return AttendanceNotifier();
});

final attendanceHistoryProvider = FutureProvider<List<AttendanceModel>>((ref) async {
  final allScans = ref.watch(liveAttendanceProvider);
  return allScans.map((r) => r.toAttendanceModel()).toList();
});

final studentAttendanceHistoryProvider = Provider.family<List<AttendanceModel>, String>((ref, regNo) {
  final allScans = ref.watch(liveAttendanceProvider);
  final studentScans = allScans.where((r) => r.registrationNo == regNo).toList();
  return studentScans.map((r) => r.toAttendanceModel()).toList();
});
