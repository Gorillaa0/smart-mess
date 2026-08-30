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

  factory SharedOrderRecord.fromFirestoreMap(Map<String, dynamic> d, String docId) {
    int extractInt(dynamic val, [int fallback = 0]) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    String extractOrderedAt(dynamic val) {
      if (val == null) return DateTime.now().toIso8601String();
      if (val is Timestamp) return val.toDate().toIso8601String();
      if (val is DateTime) return val.toIso8601String();
      return val.toString();
    }

    return SharedOrderRecord(
      id: d['id']?.toString() ?? docId,
      studentName: d['studentName']?.toString() ?? 'Student',
      registrationNo: d['registrationNo']?.toString() ?? '',
      rollNo: d['rollNo']?.toString() ?? '',
      roomNo: d['roomNo']?.toString() ?? '101',
      mobileNumber: d['mobileNumber']?.toString() ?? '',
      specialNotes: d['specialNotes']?.toString() ?? '',
      foodItemId: d['foodItemId']?.toString() ?? '',
      foodItemName: d['foodItemName']?.toString() ?? 'Special Item',
      foodItemHindi: d['foodItemHindi']?.toString() ?? '',
      unitPrice: extractInt(d['unitPrice'], 0),
      quantity: extractInt(d['quantity'], 1),
      totalBill: extractInt(d['totalBill'], 0),
      isPaid: d['isPaid'] == true,
      paymentMethod: d['paymentMethod']?.toString() ?? 'Pay on Delivery (Cash / Counter)',
      status: d['status']?.toString() ?? 'Pending Approval',
      cancellationReason: d['cancellationReason']?.toString() ?? '',
      estimatedDeliveryTime: d['estimatedDeliveryTime']?.toString() ?? '30 - 40 Mins',
      orderedAt: extractOrderedAt(d['orderedAt'] ?? d['createdAt'] ?? d['updatedAt']),
    );
  }

  factory SharedOrderRecord.fromFirestoreJson(Map<String, dynamic> fields, String fallbackId) {
    String extractString(dynamic val, [String fallback = '']) {
      if (val == null) return fallback;
      if (val is Map) return val['stringValue']?.toString() ?? val['timestampValue']?.toString() ?? val['integerValue']?.toString() ?? fallback;
      return val.toString();
    }

    int extractInt(dynamic val, [int fallback = 0]) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is Map) {
        final str = val['integerValue']?.toString() ?? val['stringValue']?.toString() ?? val['doubleValue']?.toString();
        return int.tryParse(str ?? '') ?? fallback;
      }
      return int.tryParse(val.toString()) ?? fallback;
    }

    bool extractBool(dynamic val, [bool fallback = false]) {
      if (val == null) return fallback;
      if (val is bool) return val;
      if (val is Map) return val['booleanValue'] == true;
      return val == true || val.toString().toLowerCase() == 'true';
    }

    return SharedOrderRecord(
      id: extractString(fields['id'], fallbackId),
      studentName: extractString(fields['studentName'], 'Student'),
      registrationNo: extractString(fields['registrationNo'], ''),
      rollNo: extractString(fields['rollNo'], ''),
      roomNo: extractString(fields['roomNo'], '101'),
      mobileNumber: extractString(fields['mobileNumber'], ''),
      specialNotes: extractString(fields['specialNotes'], ''),
      foodItemId: extractString(fields['foodItemId'], ''),
      foodItemName: extractString(fields['foodItemName'], 'Special Item'),
      foodItemHindi: extractString(fields['foodItemHindi'], ''),
      unitPrice: extractInt(fields['unitPrice'], 0),
      quantity: extractInt(fields['quantity'], 1),
      totalBill: extractInt(fields['totalBill'], 0),
      isPaid: extractBool(fields['isPaid'], false),
      paymentMethod: extractString(fields['paymentMethod'], 'Pay on Delivery (Cash / Counter)'),
      status: extractString(fields['status'], 'Pending Approval'),
      cancellationReason: extractString(fields['cancellationReason'], ''),
      estimatedDeliveryTime: extractString(fields['estimatedDeliveryTime'], '30 - 40 Mins'),
      orderedAt: extractString(fields['orderedAt'] ?? fields['createdAt'] ?? fields['updatedAt'], DateTime.now().toIso8601String()),
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
    if (orders.isEmpty && _inMemoryOrders.isNotEmpty) {
      // Don't wipe local cache with empty list unless explicitly cleared
      return;
    }
    _inMemoryOrders.clear();
    _inMemoryOrders.addAll(orders);
  }

  static void forceReplaceAll(List<SharedOrderRecord> orders) {
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
  Timer? _periodicSyncTimer;

  LiveOrdersGlobalNotifier() : super(SharedOrdersStore.localOrders) {
    _initFirestoreListener();
    syncLiveOrders();
    // 10s sync heartbeat to keep orders live without 429 quota exhaustion
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) => syncLiveOrders());
  }

  void _initFirestoreListener() {
    _firestoreSub?.cancel();
    try {
      _firestoreSub = FirebaseFirestore.instance
          .collection('foodOrders')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final list = <SharedOrderRecord>[];
          for (final doc in snapshot.docs) {
            list.add(SharedOrderRecord.fromFirestoreMap(doc.data(), doc.id));
          }
          list.sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
          SharedOrdersStore.forceReplaceAll(list);
          state = list;
        } else if (SharedOrdersStore.localOrders.isEmpty) {
          syncLiveOrders();
        }
      }, onError: (_) {
        syncLiveOrders();
      });
    } catch (_) {
      syncLiveOrders();
    }
  }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }

  Future<void> syncLiveOrders() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('foodOrders')
          .get()
          .timeout(const Duration(seconds: 4));

      if (snap.docs.isNotEmpty) {
        final list = <SharedOrderRecord>[];
        for (final doc in snap.docs) {
          list.add(SharedOrderRecord.fromFirestoreMap(doc.data(), doc.id));
        }
        list.sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
        SharedOrdersStore.forceReplaceAll(list);
        state = list;
        return;
      }
    } catch (_) {}

    // Fallback REST
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

        if (list.isNotEmpty) {
          list.sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
          SharedOrdersStore.forceReplaceAll(list);
          state = list;
        }
      }
    } catch (_) {}
  }

  void pushNewOrder(SharedOrderRecord order) {
    SharedOrdersStore.addOrder(order);
    state = List.from(SharedOrdersStore.localOrders);
  }

  void updateStatus(String orderId, String newStatus, {String? cancellationReason, String? deliveryTime}) {
    SharedOrdersStore.updateOrderStatus(orderId, newStatus, cancellationReason: cancellationReason, deliveryTime: deliveryTime);
    state = List.from(SharedOrdersStore.localOrders);
  }

  void clearOrders() {
    SharedOrdersStore.clearAll();
    state = [];
  }
}
