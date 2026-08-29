import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SharedOrderRecord {
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

  const SharedOrderRecord({
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

  factory SharedOrderRecord.fromFirestoreJson(Map<String, dynamic> fields, String fallbackId) {
    return SharedOrderRecord(
      id: fields['id']?['stringValue'] ?? fallbackId,
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

  SharedOrderRecord copyWith({
    String? status,
    String? cancellationReason,
    String? estimatedDeliveryTime,
  }) {
    return SharedOrderRecord(
      id: id,
      studentName: studentName,
      registrationNo: registrationNo,
      rollNo: rollNo,
      roomNo: roomNo,
      mobileNumber: mobileNumber,
      specialNotes: specialNotes,
      foodItemId: foodItemId,
      foodItemName: foodItemName,
      foodItemHindi: foodItemHindi,
      unitPrice: unitPrice,
      quantity: quantity,
      totalBill: totalBill,
      isPaid: isPaid,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      orderedAt: orderedAt,
    );
  }
}

// In-Memory Shared Cache & Live Dispatcher
class SharedOrdersStore {
  static final List<SharedOrderRecord> _inMemoryOrders = [];

  static List<SharedOrderRecord> get localOrders => List.unmodifiable(_inMemoryOrders);

  static void addOrder(SharedOrderRecord order) {
    _inMemoryOrders.removeWhere((o) => o.id == order.id);
    _inMemoryOrders.insert(0, order);
  }

  static void updateOrderStatus(String orderId, String newStatus, {String? cancellationReason, String? deliveryTime}) {
    final idx = _inMemoryOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _inMemoryOrders[idx] = _inMemoryOrders[idx].copyWith(
        status: newStatus,
        cancellationReason: cancellationReason,
        estimatedDeliveryTime: deliveryTime,
      );
    }
  }
}

final liveOrdersGlobalProvider = StateNotifierProvider<LiveOrdersGlobalNotifier, List<SharedOrderRecord>>((ref) {
  return LiveOrdersGlobalNotifier();
});

class LiveOrdersGlobalNotifier extends StateNotifier<List<SharedOrderRecord>> {
  Timer? _timer;

  LiveOrdersGlobalNotifier() : super(SharedOrdersStore.localOrders) {
    syncLiveOrders();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => syncLiveOrders());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> syncLiveOrders() async {
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
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200 && res.data is List) {
        final List data = res.data;
        final list = <SharedOrderRecord>[];

        for (final item in data) {
          if (item is Map && item['document'] != null) {
            final doc = item['document'] as Map;
            final fields = (doc['fields'] as Map?) ?? {};
            final docName = (doc['name'] as String? ?? '').split('/').last;
            final record = SharedOrderRecord.fromFirestoreJson(Map<String, dynamic>.from(fields), docName);
            list.add(record);
            SharedOrdersStore.addOrder(record);
          }
        }

        // Merge with local cache
        final mergedMap = <String, SharedOrderRecord>{};
        for (final o in SharedOrdersStore.localOrders) {
          mergedMap[o.id] = o;
        }
        for (final o in list) {
          mergedMap[o.id] = o;
        }

        final combined = mergedMap.values.toList();
        combined.sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
        state = combined;
      }
    } catch (_) {
      state = SharedOrdersStore.localOrders;
    }
  }

  void pushNewOrder(SharedOrderRecord order) {
    SharedOrdersStore.addOrder(order);
    state = SharedOrdersStore.localOrders;
  }

  void updateStatus(String orderId, String newStatus, {String? cancellationReason, String? deliveryTime}) {
    SharedOrdersStore.updateOrderStatus(orderId, newStatus, cancellationReason: cancellationReason, deliveryTime: deliveryTime);
    state = SharedOrdersStore.localOrders;
  }
}
