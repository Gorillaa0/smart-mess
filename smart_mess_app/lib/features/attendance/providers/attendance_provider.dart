import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
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

  Map<String, dynamic> toFirestoreFields() {
    return {
      'id': {'stringValue': id},
      'registrationNo': {'stringValue': registrationNo},
      'studentName': {'stringValue': studentName},
      'rollNo': {'stringValue': rollNo},
      'branch': {'stringValue': branch},
      'mealType': {'stringValue': mealType},
      'scannedAt': {'stringValue': scannedAt.toIso8601String()},
      'roomNo': {'stringValue': roomNo},
      'hostelId': {'stringValue': 'Hostel Number 4'},
    };
  }

  factory H4MealScanRecord.fromFirestoreMap(Map<String, dynamic> data, String docId) {
    return H4MealScanRecord(
      id: data['id']?.toString() ?? docId,
      registrationNo: data['registrationNo']?.toString() ?? '',
      studentName: data['studentName']?.toString() ?? '',
      rollNo: data['rollNo']?.toString() ?? '',
      branch: data['branch']?.toString() ?? '',
      mealType: data['mealType']?.toString() ?? '',
      scannedAt: DateTime.tryParse(data['scannedAt']?.toString() ?? '') ?? DateTime.now(),
      roomNo: data['roomNo']?.toString() ?? '',
    );
  }

  factory H4MealScanRecord.fromFirestoreJson(Map<String, dynamic> fields) {
    return H4MealScanRecord(
      id: fields['id']?['stringValue'] ?? '',
      registrationNo: fields['registrationNo']?['stringValue'] ?? '',
      studentName: fields['studentName']?['stringValue'] ?? '',
      rollNo: fields['rollNo']?['stringValue'] ?? '',
      branch: fields['branch']?['stringValue'] ?? '',
      mealType: fields['mealType']?['stringValue'] ?? '',
      scannedAt: DateTime.tryParse(fields['scannedAt']?['stringValue'] ?? '') ?? DateTime.now(),
      roomNo: fields['roomNo']?['stringValue'] ?? '',
    );
  }
}

class AttendanceNotifier extends StateNotifier<List<H4MealScanRecord>> {
  StreamSubscription? _sub;

  AttendanceNotifier() : super([]) {
    _initListener();
    _fetchLiveScans();
  }

  void _initListener() {
    _sub?.cancel();
    try {
      _sub = FirebaseFirestore.instance
          .collection('mealAttendance')
          .snapshots()
          .listen((snapshot) {
        final list = <H4MealScanRecord>[];
        for (final doc in snapshot.docs) {
          list.add(H4MealScanRecord.fromFirestoreMap(doc.data(), doc.id));
        }
        list.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
        state = list;
      }, onError: (_) {
        _fetchLiveScans();
      });
    } catch (_) {
      _fetchLiveScans();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveScans() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('mealAttendance')
          .get()
          .timeout(const Duration(seconds: 4));

      if (snap.docs.isNotEmpty) {
        final list = <H4MealScanRecord>[];
        for (final doc in snap.docs) {
          list.add(H4MealScanRecord.fromFirestoreMap(doc.data(), doc.id));
        }
        list.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
        state = list;
        return;
      }
    } catch (_) {}

    try {
      final dio = Dio();
      final res = await dio.post(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'structuredQuery': {
            'from': [{'collectionId': 'mealAttendance'}]
          }
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200 && res.data is List) {
        final List results = res.data;
        final list = <H4MealScanRecord>[];

        for (final item in results) {
          if (item is Map && item['document'] != null) {
            final doc = item['document'] as Map;
            final fields = (doc['fields'] as Map?) ?? {};
            list.add(H4MealScanRecord.fromFirestoreJson(Map<String, dynamic>.from(fields)));
          }
        }

        list.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
        state = list;
      }
    } catch (_) {}
  }

  bool hasScanned(String registrationNo, String mealType) {
    final today = DateTime.now().toLocal();
    final cleanMeal = mealType.toLowerCase().trim();
    return state.any((record) {
      final recDate = record.scannedAt.toLocal();
      final isSameDay = recDate.day == today.day &&
          recDate.month == today.month &&
          recDate.year == today.year;
      final isSameStudent = record.registrationNo.trim() == registrationNo.trim() ||
          record.rollNo.trim() == registrationNo.trim();
      final recMeal = record.mealType.toLowerCase().trim();
      final isSameMeal = recMeal == cleanMeal ||
          recMeal.contains(cleanMeal) ||
          cleanMeal.contains(recMeal);
      return isSameStudent && isSameMeal && isSameDay;
    });
  }

  Future<bool> recordScan(H4Student student, String mealType) async {
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

    // Optimistic update
    state = [newRecord, ...state];

    // Save permanently to Firestore
    try {
      final dio = Dio();
      await dio.patch(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/mealAttendance/${newRecord.id}?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {'fields': newRecord.toFirestoreFields()},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } catch (_) {}

    return true;
  }

  List<H4MealScanRecord> getStudentHistory(String registrationNo) {
    return state.where((s) => s.registrationNo == registrationNo).toList();
  }

  int getTodayMealCount(String mealType) {
    final today = DateTime.now().toLocal();
    final cleanMeal = mealType.toLowerCase().trim();
    return state.where((r) {
      final recDate = r.scannedAt.toLocal();
      final isSameDay = recDate.day == today.day &&
          recDate.month == today.month &&
          recDate.year == today.year;
      final recMeal = r.mealType.toLowerCase().trim();
      final isSameMeal = recMeal == cleanMeal ||
          recMeal.contains(cleanMeal) ||
          cleanMeal.contains(recMeal);
      return isSameMeal && isSameDay;
    }).length;
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
