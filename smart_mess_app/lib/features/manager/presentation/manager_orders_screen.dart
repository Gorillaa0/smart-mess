import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/special_food_item.dart';
import '../../../core/services/shared_orders_store.dart';

class ManagerOrdersScreen extends ConsumerStatefulWidget {
  const ManagerOrdersScreen({super.key});

  @override
  ConsumerState<ManagerOrdersScreen> createState() => _ManagerOrdersScreenState();
}

class _ManagerOrdersScreenState extends ConsumerState<ManagerOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'All';
  List<SpecialFoodItem> _menuItems = kDefaultSpecialFoodMenu;
  bool _isMenuLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMenuItems();
    // Trigger a fresh Firestore sync immediately when the manager opens this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveOrdersGlobalProvider.notifier).syncLiveOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMenuItems({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isMenuLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('specialFoodMenu')
          .get()
          .timeout(const Duration(seconds: 4));

      if (snap.docs.isNotEmpty) {
        final list = <SpecialFoodItem>[];
        for (final doc in snap.docs) {
          list.add(SpecialFoodItem.fromFirestoreMap(doc.data(), doc.id));
        }
        if (list.isNotEmpty && mounted) {
          setState(() {
            _menuItems = list;
            _isMenuLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    try {
      final dio = Dio();
      final res = await dio.post(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'structuredQuery': {
            'from': [{'collectionId': 'specialFoodMenu'}]
          }
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && res.data is List) {
        final List data = res.data;
        final list = <SpecialFoodItem>[];

        for (final item in data) {
          if (item is Map && item['document'] != null) {
            final doc = item['document'] as Map;
            final fields = (doc['fields'] as Map?) ?? {};
            list.add(SpecialFoodItem.fromFirestoreJson(Map<String, dynamic>.from(fields)));
          }
        }

        if (list.isNotEmpty && mounted) {
          setState(() {
            _menuItems = list;
            _isMenuLoading = false;
          });
        } else {
          if (mounted) setState(() => _isMenuLoading = false);
        }
      } else {
        if (mounted) setState(() => _isMenuLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isMenuLoading = false);
    }
  }

  Future<void> _updateOrderStatus(BuildContext context, String orderId, String newStatus, String deliveryTime) async {
    ref.read(liveOrdersGlobalProvider.notifier).updateStatus(orderId, newStatus, deliveryTime: deliveryTime);

    try {
      try {
        await FirebaseFirestore.instance.collection('foodOrders').doc(orderId).update({
          'status': newStatus,
          'estimatedDeliveryTime': deliveryTime,
          'updatedAt': DateTime.now().toIso8601String(),
        }).timeout(const Duration(seconds: 2));
      } catch (_) {
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
        ).timeout(const Duration(seconds: 3));
      }

      ref.read(liveOrdersGlobalProvider.notifier).syncLiveOrders();

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

  Future<void> _cancelOrderWithReason(BuildContext context, String orderId, String cancellationReason) async {
    ref.read(liveOrdersGlobalProvider.notifier).updateStatus(orderId, 'Cancelled', cancellationReason: cancellationReason);

    try {
      try {
        await FirebaseFirestore.instance.collection('foodOrders').doc(orderId).update({
          'status': 'Cancelled',
          'cancellationReason': cancellationReason,
          'updatedAt': DateTime.now().toIso8601String(),
        }).timeout(const Duration(seconds: 2));
      } catch (_) {
        final dio = Dio();
        await dio.patch(
          'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/foodOrders/$orderId?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E&updateMask.fieldPaths=status&updateMask.fieldPaths=cancellationReason&updateMask.fieldPaths=updatedAt',
          data: {
            'fields': {
              'status': {'stringValue': 'Cancelled'},
              'cancellationReason': {'stringValue': cancellationReason},
              'updatedAt': {'stringValue': DateTime.now().toIso8601String()},
            }
          },
          options: Options(headers: {'Content-Type': 'application/json'}),
        ).timeout(const Duration(seconds: 3));
      }

      ref.read(liveOrdersGlobalProvider.notifier).syncLiveOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled and reason sent to student!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling order: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showCancelDialog(BuildContext context, Map<String, dynamic> order) {
    final reasonController = TextEditingController(text: 'Kitchen out of ingredients / Heavy rush');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
              SizedBox(width: 8),
              Text('Cancel Food Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: ${order['studentName']} (Room ${order['roomNo']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Item: ${order['foodItemName']} (x${order['quantity']}) • ₹${order['totalBill']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 14),
              const Text('Enter Cancellation Reason:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Out of eggs/paneer, kitchen closed, high rush...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  'Out of stock',
                  'Kitchen heavy rush',
                  'Delivery not possible now',
                  'Item unavailable',
                ].map((reason) {
                  return ActionChip(
                    label: Text(reason, style: const TextStyle(fontSize: 10)),
                    onPressed: () => reasonController.text = reason,
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final r = reasonController.text.trim();
                Navigator.pop(ctx);
                _cancelOrderWithReason(context, order['id'], r.isEmpty ? 'Order cancelled by mess manager' : r);
              },
              child: const Text('CONFIRM CANCEL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditOrCreateDialog(BuildContext context, {SpecialFoodItem? item}) {
    final isCreating = item == null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final hindiController = TextEditingController(text: item?.hindiName ?? '');
    final priceController = TextEditingController(text: item != null ? item.price.toString() : '50');
    final descController = TextEditingController(text: item?.description ?? '');
    bool isAvail = item?.isAvailable ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(isCreating ? Icons.add_circle : Icons.edit, color: const Color(0xFF1B5E20), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCreating ? 'Create New Special Food Item' : 'Edit Special Food Item',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Food Item Name (English) *',
                    hintText: 'e.g. Crispy Spring Roll / Paneer Roll',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hindiController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name (Hindi Optional)',
                    hintText: 'e.g. स्प्रिंग रोल',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price Rate (₹) *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description / Ingredients',
                    hintText: 'e.g. Fresh vegetables, special herbs & cheese',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available for Ordering', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  value: isAvail,
                  activeColor: const Color(0xFF1B5E20),
                  onChanged: (v) => setDialogState(() => isAvail = v),
                ),
              ],
            ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final hindi = hindiController.text.trim();
                final price = int.tryParse(priceController.text.trim()) ?? 50;
                final desc = descController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter food item name'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }

                final itemId = isCreating
                    ? 'item_${DateTime.now().millisecondsSinceEpoch}'
                    : item.id;

                final newItem = SpecialFoodItem(
                  id: itemId,
                  name: name,
                  hindiName: hindi,
                  price: price,
                  description: desc,
                  isAvailable: isAvail,
                );

                Navigator.pop(ctx);

                try {
                  final dio = Dio();
                  await dio.patch(
                    'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/specialFoodMenu/$itemId?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
                    data: {'fields': newItem.toFirestoreFields()},
                    options: Options(headers: {'Content-Type': 'application/json'}),
                  );

                  _fetchMenuItems(silent: true);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isCreating
                            ? 'Created "$name" (₹$price)! Synced to Student Dashboard.'
                            : 'Updated "$name" price to ₹$price! Synced.'),
                        backgroundColor: const Color(0xFF1B5E20),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save item: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: Text(
                isCreating ? 'CREATE & SYNC' : 'SAVE & SYNC TO STUDENTS',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
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
              Text('Total Bill: ₹${order['totalBill']} • ${order['paymentMethod'] ?? "Pay on Delivery"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFE65100))),
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
    final liveGlobalOrders = ref.watch(liveOrdersGlobalProvider);

    final allOrdersList = liveGlobalOrders.map<Map<String, dynamic>>((o) => <String, dynamic>{
      'id': o.id,
      'studentName': o.studentName,
      'registrationNo': o.registrationNo,
      'rollNo': o.rollNo,
      'roomNo': o.roomNo,
      'mobileNumber': o.mobileNumber,
      'specialNotes': o.specialNotes,
      'foodItemId': o.foodItemId,
      'foodItemName': o.foodItemName,
      'foodItemHindi': o.foodItemHindi,
      'unitPrice': o.unitPrice,
      'quantity': o.quantity,
      'totalBill': o.totalBill,
      'isPaid': o.isPaid,
      'paymentMethod': o.paymentMethod,
      'status': o.status,
      'cancellationReason': o.cancellationReason,
      'estimatedDeliveryTime': o.estimatedDeliveryTime,
      'orderedAt': o.orderedAt,
    }).toList();

    allOrdersList.sort((a, b) => ((b['orderedAt'] as String?) ?? '').compareTo((a['orderedAt'] as String?) ?? ''));

    final filtered = allOrdersList.where((o) {
      if (_selectedStatus == 'All') return true;
      return (o['status'] ?? '').toString().toLowerCase() == _selectedStatus.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Special Food Desk & Menu Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(liveOrdersGlobalProvider.notifier).syncLiveOrders();
              _fetchMenuItems();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1B5E20),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1B5E20),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Student Orders'),
            Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Manage Menu & Rates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Real-time Orders Ledger
          Column(
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
                      final count = st == 'All' ? allOrdersList.length : allOrdersList.where((o) => (o['status'] ?? '').toString().toLowerCase() == st.toLowerCase()).length;
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

              Expanded(
                child: liveGlobalOrders.isEmpty && SharedOrdersStore.localOrders.isEmpty
                    ? filtered.isEmpty
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
                        : const SizedBox.shrink()
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
                            onRefresh: () => ref.read(liveOrdersGlobalProvider.notifier).syncLiveOrders(),
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
                                final notes = order['specialNotes'] ?? '';
                                final status = order['status'] ?? 'Pending Approval';
                                final reason = order['cancellationReason'] ?? '';
                                final estTime = order['estimatedDeliveryTime'] ?? '30 - 40 Mins';

                                Color statusColor = Colors.orange;
                                if (status == 'Delivered') statusColor = Colors.green;
                                if (status == 'Preparing') statusColor = Colors.blue;
                                if (status == 'Cancelled') statusColor = Colors.red;

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
                                          Expanded(
                                            child: Text(
                                              'Student: $student (Room $room, H4)',
                                              style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w700),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('₹$total', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFE65100))),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone, size: 13, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Phone: $phone',
                                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.amber.shade300),
                                            ),
                                            child: const Text('PAY ON DELIVERY',
                                                style: TextStyle(color: Color(0xFFBF360C), fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      if (notes.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF8E1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFFFE082)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.note_alt_outlined, size: 14, color: Color(0xFFE65100)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text('Special Mention: "$notes"',
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFFBF360C), fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (status == 'Cancelled' && reason.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFEBEE),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFFFCDD2)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text('Cancelled Reason: "$reason"',
                                                    style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
                                          if (status != 'Delivered' && status != 'Cancelled') ...[
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red.shade700,
                                                side: BorderSide(color: Colors.red.shade300),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              icon: const Icon(Icons.cancel_outlined, size: 15),
                                              label: const Text('CANCEL ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                              onPressed: () => _showCancelDialog(context, order),
                                            ),
                                            const SizedBox(width: 8),
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

          // TAB 2: Manage Special Food Items & Prices + CREATE NEW ITEM
          _isMenuLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header card with Create New Item Action
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Color(0xFF1B5E20), size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Create new items or edit rates. Anything added appears live in the student app!',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('+ CREATE NEW FOOD ITEM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              onPressed: () => _showEditOrCreateDialog(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    ..._menuItems.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: item.isAvailable ? Colors.grey.shade300 : Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.isAvailable ? const Color(0xFFFFF3E0) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.fastfood, color: item.isAvailable ? const Color(0xFFE65100) : Colors.grey, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                      if (!item.isAvailable) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                                          child: const Text('UNAVAILABLE', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (item.hindiName.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(item.hindiName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  ],
                                  const SizedBox(height: 2),
                                  Text('Rate: ₹${item.price}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF1B5E20), size: 20),
                              tooltip: 'Edit Price & Details',
                              onPressed: () => _showEditOrCreateDialog(context, item: item),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ],
      ),
    );
  }
}
