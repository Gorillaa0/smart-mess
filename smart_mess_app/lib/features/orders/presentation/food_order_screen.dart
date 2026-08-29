import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/h4_students_data.dart';
import '../../../core/models/special_food_item.dart';
import '../../../core/router/app_router.dart';

class FoodOrderScreen extends ConsumerStatefulWidget {
  const FoodOrderScreen({super.key});

  @override
  ConsumerState<FoodOrderScreen> createState() => _FoodOrderScreenState();
}

class _FoodOrderScreenState extends ConsumerState<FoodOrderScreen> {
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  List<SpecialFoodItem> _menuItems = kDefaultSpecialFoodMenu;
  SpecialFoodItem _selectedItem = kDefaultSpecialFoodMenu[0];
  int _quantity = 1;
  bool _isSubmitting = false;
  Timer? _menuTimer;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '9876543210';
    _fetchLiveSpecialFoodMenu();
    _menuTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchLiveSpecialFoodMenu());
  }

  @override
  void dispose() {
    _menuTimer?.cancel();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveSpecialFoodMenu() async {
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
      ).timeout(const Duration(seconds: 3));

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
            // update currently selected item if in menu
            final match = _menuItems.where((i) => i.id == _selectedItem.id).toList();
            if (match.isNotEmpty) {
              _selectedItem = match.first;
            } else {
              _selectedItem = _menuItems.first;
            }
          });
        }
      }
    } catch (_) {}
  }

  void _placeOrder() async {
    final student = ref.read(currentStudentProvider);
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final totalBill = _selectedItem.price * _quantity;
    setState(() => _isSubmitting = true);

    try {
      final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}_${student.rollNo}';
      final now = DateTime.now();

      final dio = Dio();
      await dio.patch(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/foodOrders/$orderId?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'fields': {
            'id': {'stringValue': orderId},
            'studentName': {'stringValue': student.name},
            'registrationNo': {'stringValue': student.registrationNo},
            'rollNo': {'stringValue': student.rollNo},
            'roomNo': {'stringValue': student.roomNo},
            'mobileNumber': {'stringValue': phone},
            'foodItemId': {'stringValue': _selectedItem.id},
            'foodItemName': {'stringValue': _selectedItem.name},
            'foodItemHindi': {'stringValue': _selectedItem.hindiName},
            'unitPrice': {'integerValue': _selectedItem.price.toString()},
            'quantity': {'integerValue': _quantity.toString()},
            'totalBill': {'integerValue': totalBill.toString()},
            'isPaid': {'booleanValue': false}, // Offline / Cash on Delivery
            'paymentMethod': {'stringValue': 'Pay on Delivery (Cash / Counter)'},
            'status': {'stringValue': 'Pending Approval'},
            'estimatedDeliveryTime': {'stringValue': '30 - 40 Mins'},
            'specialNotes': {'stringValue': _notesController.text.trim()},
            'orderedAt': {'stringValue': now.toIso8601String()},
            'updatedAt': {'stringValue': now.toIso8601String()},
          }
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF1B5E20), size: 26),
                SizedBox(width: 8),
                Text('Order Placed Successfully!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: Color(0xFF1B5E20))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item: ${_selectedItem.name} (x$_quantity)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text('Total Bill: ₹$totalBill', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFFE65100))),
                const SizedBox(height: 2),
                const Text('Payment Mode: Pay on Delivery (Cash / Counter)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 6),
                Text('Delivery to: Room ${student.roomNo}, Hostel 4', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.timer, color: Color(0xFF1B5E20), size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Estimated Delivery: 30–40 Mins after manager confirmation',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('OKAY', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProvider);
    final totalBill = _selectedItem.price * _quantity;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Order Special Mess Food', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Student Details Card (Auto Filled)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA5D6A7)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_pin, color: Color(0xFF1B5E20), size: 18),
                    SizedBox(width: 6),
                    Text('Resident & Delivery Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1B5E20))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Student Name', style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Room & Hostel', style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text('Room ${student.roomNo}, Hostel 4', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number for Delivery Updates',
                    prefixIcon: const Icon(Icons.phone_android, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Available Food Items Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SELECT AVAILABLE SPECIAL FOOD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.black87, letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                child: const Text('Live Manager Rates', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Column(
            children: _menuItems.where((i) => i.isAvailable).map((item) {
              final isSelected = _selectedItem.id == item.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedItem = item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.fastfood, color: isSelected ? Colors.white : const Color(0xFFE65100), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                Text('₹${item.price}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1B5E20))),
                              ],
                            ),
                            if (item.hindiName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(item.hindiName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(item.description, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Quantity & Payment Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B5E20)),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payable Bill:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('₹$totalBill', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFFE65100))),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.handshake_outlined, color: Color(0xFFE65100), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Method: Pay on Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFBF360C))),
                            Text('Pay directly in cash or counter at delivery time', style: TextStyle(fontSize: 10.5, color: Colors.brown)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.shopping_bag, size: 20),
              label: Text(_isSubmitting ? 'PLACING ORDER...' : 'CONFIRM ORDER (₹$totalBill - PAY ON DELIVERY)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: _isSubmitting ? null : _placeOrder,
            ),
          ),
        ],
      ),
    );
  }
}
