import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagerOrdersScreen extends ConsumerStatefulWidget {
  const ManagerOrdersScreen({super.key});

  @override
  ConsumerState<ManagerOrdersScreen> createState() => _ManagerOrdersScreenState();
}

class _ManagerOrdersScreenState extends ConsumerState<ManagerOrdersScreen> {
  String _selectedStatus = 'All';
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchOrders(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
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
        final list = <Map<String, dynamic>>[];

        for (final item in data) {
          if (item is Map && item['document'] != null) {
            final doc = item['document'] as Map;
            final fields = (doc['fields'] as Map?) ?? {};
            final docName = (doc['name'] as String? ?? '').split('/').isNotEmpty ? (doc['name'] as String? ?? '').split('/').last : '';
            
            list.add({
              'id': fields['id']?['stringValue'] ?? docName,
              'studentName': fields['studentName']?['stringValue'] ?? 'Student',
              'registrationNo': fields['registrationNo']?['stringValue'] ?? '',
              'rollNo': fields['rollNo']?['stringValue'] ?? '',
              'roomNo': fields['roomNo']?['stringValue'] ?? '101',
              'mobileNumber': fields['mobileNumber']?['stringValue'] ?? '',
              'foodItemId': fields['foodItemId']?['stringValue'] ?? '',
              'foodItemName': fields['foodItemName']?['stringValue'] ?? 'Special Item',
              'foodItemHindi': fields['foodItemHindi']?['stringValue'] ?? '',
              'unitPrice': int.tryParse(fields['unitPrice']?['integerValue'] ?? '0') ?? 0,
              'quantity': int.tryParse(fields['quantity']?['integerValue'] ?? '1') ?? 1,
              'totalBill': int.tryParse(fields['totalBill']?['integerValue'] ?? '0') ?? 0,
              'isPaid': fields['isPaid']?['booleanValue'] ?? true,
              'status': fields['status']?['stringValue'] ?? 'Pending Approval',
              'estimatedDeliveryTime': fields['estimatedDeliveryTime']?['stringValue'] ?? '30 - 40 Mins',
              'orderedAt': fields['orderedAt']?['stringValue'] ?? '',
            });
          }
        }

        list.sort((a, b) => (b['orderedAt'] ?? '').compareTo(a['orderedAt'] ?? ''));
        if (mounted) {
          setState(() {
            _orders = list;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(BuildContext context, String orderId, String newStatus, String deliveryTime) async {
    try {
      final dio = Dio();
      await dio.patch(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/foodOrders/$orderId?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E&updateMask.fieldPaths=status&updateMask.fieldPaths=estimatedDeliveryTime&updateMask.fieldPaths=updatedAt',
        data: {
          'fields': {
            'status': {'stringValue': newStatus},
            'estimatedDeliveryTime': {'stringValue': deliveryTime},
            'updatedAt': {'stringValue': DateTime.now().toIso8601String()},
          }
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      _fetchOrders(silent: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as "$newStatus" ($deliveryTime delivery)!'),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showConfirmDialog(BuildContext context, Map<String, dynamic> order) {
    String selectedTime = '30 - 40 Mins';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.soup_kitchen, color: Color(0xFF1B5E20), size: 24),
              SizedBox(width: 8),
              Text('Accept & Prepare Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Item: ${order['foodItemName']} (x${order['quantity']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Student: ${order['studentName']} (Room ${order['roomNo']})', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text('Total Bill: ₹${order['totalBill']} • ${order['isPaid'] == true ? "PAID ONLINE" : "UNPAID (Pay on delivery)"}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: order['isPaid'] == true ? Colors.green : Colors.redAccent)),
              const SizedBox(height: 14),
              const Text('Estimated Delivery Time:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['20 - 30 Mins', '30 - 40 Mins', '45 - 60 Mins'].map((time) {
                  final isSel = selectedTime == time;
                  return ChoiceChip(
                    label: Text(time),
                    selected: isSel,
                    selectedColor: const Color(0xFF1B5E20),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedTime = time);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _updateOrderStatus(context, order['id'], 'Preparing', selectedTime);
              },
              child: const Text('CONFIRM & PREPARE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _orders.where((o) {
      if (_selectedStatus == 'All') return true;
      return (o['status'] ?? '').toString().toLowerCase() == _selectedStatus.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Special Food Orders Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Pending Approval', 'Preparing', 'Delivered'].map((st) {
                  final isSelected = _selectedStatus == st;
                  final count = st == 'All' ? _orders.length : _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == st.toLowerCase()).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$st ($count)'),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1B5E20),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedStatus = st);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Orders List with Instant Loading Timeout Safeguard
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.soup_kitchen_outlined, size: 64, color: Colors.green.shade300),
                            const SizedBox(height: 12),
                            Text('No food orders matching "$_selectedStatus"',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Orders placed by students will arrive here in real time', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            final item = order['foodItemName'] ?? 'Special Item';
                            final qty = order['quantity'] ?? 1;
                            final total = order['totalBill'] ?? 0;
                            final student = order['studentName'] ?? 'Student';
                            final room = order['roomNo'] ?? '101';
                            final phone = order['mobileNumber'] ?? '';
                            final isPaid = order['isPaid'] == true;
                            final status = order['status'] ?? 'Pending Approval';
                            final estTime = order['estimatedDeliveryTime'] ?? '30 - 40 Mins';

                            Color statusColor = Colors.orange;
                            if (status == 'Delivered') statusColor = Colors.green;
                            if (status == 'Preparing') statusColor = Colors.blue;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: statusColor.withOpacity(0.4), width: 1.2),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text('$item (x$qty)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor.withOpacity(0.4)),
                                        ),
                                        child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Student: $student (Room $room, H4)', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                      Text('₹$total', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFE65100))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 13, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text('Phone: $phone', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: isPaid ? Colors.green.shade200 : Colors.red.shade200),
                                        ),
                                        child: Text(isPaid ? 'PAID ONLINE' : 'PAY ON DELIVERY',
                                            style: TextStyle(color: isPaid ? Colors.green.shade800 : Colors.red.shade800, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F8E9), borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delivery_dining, size: 15, color: Color(0xFF1B5E20)),
                                        const SizedBox(width: 6),
                                        Text('Estimated Delivery: $estTime', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (status != 'Delivered') ...[
                                        if (status == 'Pending Approval')
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1B5E20),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.check, size: 16),
                                            label: const Text('CONFIRM & PREPARE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                            onPressed: () => _showConfirmDialog(context, order),
                                          ),
                                        if (status == 'Preparing')
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1565C0),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.delivery_dining, size: 16),
                                            label: const Text('MARK AS DELIVERED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                            onPressed: () => _updateOrderStatus(context, order['id'], 'Delivered', estTime),
                                          ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
