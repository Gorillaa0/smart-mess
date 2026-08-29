import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  static void replaceAll(List<SharedOrderRecord> orders) {
    _inMemoryOrders.clear();
    _inMemoryOrders.addAll(orders);
  }

  static void clearAll() {
    _inMemoryOrders.clear();
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
  StreamSubscription? _firestoreSub;
  Timer? _fallbackTimer;
  bool _streamActive = false;

  LiveOrdersGlobalNotifier() : super(SharedOrdersStore.localOrders) {
    _initFirestoreListener();
  }

  void _initFirestoreListener() {
    _firestoreSub?.cancel();
    _streamActive = false;
    try {
      _firestoreSub = FirebaseFirestore.instance
          .collection('foodOrders')
          .orderBy('orderedAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        _streamActive = true;
        _fallbackTimer?.cancel(); // Stream is live, no need for polling fallback
        final list = <SharedOrderRecord>[];
        for (final doc in snapshot.docs) {
          final d = doc.data();
          final record = SharedOrderRecord(
            id: doc.id,
            studentName: d['studentName']?.toString() ?? 'Student',
            registrationNo: d['registrationNo']?.toString() ?? '',
            rollNo: d['rollNo']?.toString() ?? '',
            roomNo: d['roomNo']?.toString() ?? '101',
            mobileNumber: d['mobileNumber']?.toString() ?? '',
            specialNotes: d['specialNotes']?.toString() ?? '',
            foodItemId: d['foodItemId']?.toString() ?? '',
            foodItemName: d['foodItemName']?.toString() ?? 'Special Item',
            foodItemHindi: d['foodItemHindi']?.toString() ?? '',
            unitPrice: int.tryParse(d['unitPrice']?.toString() ?? '0') ?? 0,
            quantity: int.tryParse(d['quantity']?.toString() ?? '1') ?? 1,
            totalBill: int.tryParse(d['totalBill']?.toString() ?? '0') ?? 0,
            isPaid: d['isPaid'] == true,
            paymentMethod: d['paymentMethod']?.toString() ?? 'Pay on Delivery',
            status: d['status']?.toString() ?? 'Pending Approval',
            cancellationReason: d['cancellationReason']?.toString() ?? '',
            estimatedDeliveryTime: d['estimatedDeliveryTime']?.toString() ?? '30 - 40 Mins',
            orderedAt: d['orderedAt']?.toString() ?? DateTime.now().toIso8601String(),
          );
          list.add(record);
        }

        SharedOrdersStore.replaceAll(list);
        list.sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
        state = list;
      }, onError: (_) {
        _streamActive = false;
        // Stream failed — start periodic REST fallback every 30s until stream recovers
        _startFallbackPolling();
        // Also attempt to reconnect the stream after 10s
        Future.delayed(const Duration(seconds: 10), () {
          if (!_streamActive) _initFirestoreListener();
        });
      });
    } catch (_) {
      _streamActive = false;
      _startFallbackPolling();
    }
  }

  void _startFallbackPolling() {
    _fallbackTimer?.cancel();
    // Do an immediate sync first
    syncLiveOrders();
    // Then poll every 30s as a fallback (not aggressive — avoids 429 quota errors)
    _fallbackTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_streamActive) syncLiveOrders();
    });
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    _fallbackTimer?.cancel();
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
          }
        }

        SharedOrdersStore.replaceAll(list);
        list.sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
        state = list;
      }
    } catch (_) {}
  }

  void pushNewOrder(SharedOrderRecord order) {
    SharedOrdersStore.addOrder(order);
    state = SharedOrdersStore.localOrders;
  }

  void updateStatus(String orderId, String newStatus, {String? cancellationReason, String? deliveryTime}) {
    SharedOrdersStore.updateOrderStatus(orderId, newStatus, cancellationReason: cancellationReason, deliveryTime: deliveryTime);
    state = SharedOrdersStore.localOrders;
  }

  void clearOrders() {
    SharedOrdersStore.clearAll();
    state = [];
  }
}
