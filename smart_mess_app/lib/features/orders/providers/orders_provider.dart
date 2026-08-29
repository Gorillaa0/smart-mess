import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';

class StudentOrderModel {
  final String id;
  final String studentName;
  final String registrationNo;
  final String rollNo;
  final String roomNo;
  final String mobileNumber;
  final String specialNotes;
  final String foodItemId;
  final String foodItemName;
  final String foodItemHindi;
  final int unitPrice;
  final int quantity;
  final int totalBill;
  final bool isPaid;
  final String paymentMethod;
  final String status;
  final String cancellationReason;
  final String estimatedDeliveryTime;
  final String orderedAt;

  const StudentOrderModel({
    required this.id,
    required this.studentName,
    required this.registrationNo,
    required this.rollNo,
    required this.roomNo,
    required this.mobileNumber,
    required this.specialNotes,
    required this.foodItemId,
    required this.foodItemName,
    required this.foodItemHindi,
    required this.unitPrice,
    required this.quantity,
    required this.totalBill,
    required this.isPaid,
    required this.paymentMethod,
    required this.status,
    required this.cancellationReason,
    required this.estimatedDeliveryTime,
    required this.orderedAt,
  });

  factory StudentOrderModel.fromFirestoreJson(Map<String, dynamic> fields, String docName) {
    return StudentOrderModel(
      id: fields['id']?['stringValue'] ?? docName,
      studentName: fields['studentName']?['stringValue'] ?? 'Student',
      registrationNo: fields['registrationNo']?['stringValue'] ?? '',
      rollNo: fields['rollNo']?['stringValue'] ?? '',
      roomNo: fields['roomNo']?['stringValue'] ?? '101',
      mobileNumber: fields['mobileNumber']?['stringValue'] ?? '',
      specialNotes: fields['specialNotes']?['stringValue'] ?? '',
      foodItemId: fields['foodItemId']?['stringValue'] ?? '',
      foodItemName: fields['foodItemName']?['stringValue'] ?? 'Special Item',
      foodItemHindi: fields['foodItemHindi']?['stringValue'] ?? '',
      unitPrice: int.tryParse(fields['unitPrice']?['integerValue'] ?? '0') ?? 0,
      quantity: int.tryParse(fields['quantity']?['integerValue'] ?? '1') ?? 1,
      totalBill: int.tryParse(fields['totalBill']?['integerValue'] ?? '0') ?? 0,
      isPaid: fields['isPaid']?['booleanValue'] ?? false,
      paymentMethod: fields['paymentMethod']?['stringValue'] ?? 'Pay on Delivery',
      status: fields['status']?['stringValue'] ?? 'Pending Approval',
      cancellationReason: fields['cancellationReason']?['stringValue'] ?? '',
      estimatedDeliveryTime: fields['estimatedDeliveryTime']?['stringValue'] ?? '30 - 40 Mins',
      orderedAt: fields['orderedAt']?['stringValue'] ?? '',
    );
  }
}

final studentOrdersListProvider = StateNotifierProvider<StudentOrdersNotifier, List<StudentOrderModel>>((ref) {
  final student = ref.watch(currentStudentProvider);
  return StudentOrdersNotifier(student.registrationNo, student.rollNo);
});

class StudentOrdersNotifier extends StateNotifier<List<StudentOrderModel>> {
  final String _regNo;
  final String _rollNo;
  Timer? _pollTimer;

  StudentOrdersNotifier(this._regNo, this._rollNo) : super([]) {
    fetchOrders();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => fetchOrders());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    try {
      final dio = Dio();
      final res = await dio.post(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'structuredQuery': {
            'from': [{'collectionId': 'foodOrders'}]
          }
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && res.data is List) {
        final List data = res.data;
        final list = <StudentOrderModel>[];

        for (final item in data) {
          if (item is Map && item['document'] != null) {
            final doc = item['document'] as Map;
            final fields = (doc['fields'] as Map?) ?? {};
            final docName = (doc['name'] as String? ?? '').split('/').last;
            final reg = fields['registrationNo']?['stringValue'] ?? '';
            final roll = fields['rollNo']?['stringValue'] ?? '';

            if (reg == _regNo || roll == _rollNo || _regNo.isEmpty) {
              list.add(StudentOrderModel.fromFirestoreJson(Map<String, dynamic>.from(fields), docName));
            }
          }
        }

        list.sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
        state = list;
      }
    } catch (_) {}
  }
}
