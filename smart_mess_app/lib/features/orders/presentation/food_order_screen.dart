import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/h4_students_data.dart';
import '../../../core/router/app_router.dart';

class SpecialFoodItem {
  final String id;
  final String name;
  final String hindiName;
  final int price;
  final String description;
  final IconData icon;

  const SpecialFoodItem({
    required this.id,
    required this.name,
    required this.hindiName,
    required this.price,
    required this.description,
    required this.icon,
  });
}

const List<SpecialFoodItem> kAvailableSpecialFoods = [
  SpecialFoodItem(
    id: 'egg_roll',
    name: 'Special Double Egg Roll',
    hindiName: 'स्पेशल डबल एग रोल',
    price: 45,
    description: 'Crispy laccha paratha with 2 eggs, onions, green chili & sauces',
    icon: Icons.fastfood,
  ),
  SpecialFoodItem(
    id: 'paneer_roll',
    name: 'Paneer Tikka Roll',
    hindiName: 'पनीर टिक्का रोल',
    price: 60,
    description: 'Fresh grilled paneer cubes wrapped in toasted flaky paratha',
    icon: Icons.wrap_text,
  ),
  SpecialFoodItem(
    id: 'chowmein',
    name: 'Veg Hakka Chowmein',
    hindiName: 'वेज हक्का चाउमीन',
    price: 40,
    description: 'Wok-tossed noodles with crunchy capsicum, cabbage & spicy seasoning',
    icon: Icons.ramen_dining,
  ),
  SpecialFoodItem(
    id: 'burger',
    name: 'Crispy Veg / Chicken Burger',
    hindiName: 'क्रिस्पी वेज / चिकन बर्गर',
    price: 50,
    description: 'Grilled patty with cheese slice, fresh lettuce, tomato & mayo',
    icon: Icons.lunch_dining,
  ),
  SpecialFoodItem(
    id: 'maggi',
    name: 'Special Cheese Butter Maggi',
    hindiName: 'चीज बटर मैगी',
    price: 35,
    description: 'Double noodles with melted Amul butter, cheese & veggies',
    icon: Icons.soup_kitchen,
  ),
];

class FoodOrderScreen extends ConsumerStatefulWidget {
  const FoodOrderScreen({super.key});

  @override
  ConsumerState<FoodOrderScreen> createState() => _FoodOrderScreenState();
}

class _FoodOrderScreenState extends ConsumerState<FoodOrderScreen> {
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Selected food item & quantity
  SpecialFoodItem _selectedItem = kAvailableSpecialFoods[0];
  int _quantity = 1;
  bool _isPaid = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '9876543210';
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
      final docRef = FirebaseFirestore.instance.collection('foodOrders').doc();
      final now = DateTime.now();

      await docRef.set({
        'id': docRef.id,
        'studentName': student.name,
        'registrationNo': student.registrationNo,
        'rollNo': student.rollNo,
        'roomNo': student.roomNo,
        'mobileNumber': phone,
        'foodItemId': _selectedItem.id,
        'foodItemName': _selectedItem.name,
        'foodItemHindi': _selectedItem.hindiName,
        'unitPrice': _selectedItem.price,
        'quantity': _quantity,
        'totalBill': totalBill,
        'isPaid': _isPaid,
        'paymentMethod': _isPaid ? 'UPI / Online' : 'Pay at Counter',
        'status': 'Pending Approval',
        'estimatedDeliveryTime': '30 - 40 Mins',
        'specialNotes': _notesController.text.trim(),
        'orderedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF1B5E20), size: 26),
                SizedBox(width: 8),
                Text('Order Placed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1B5E20))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item: ${_selectedItem.name} (x$_quantity)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text('Total Bill: ₹$totalBill (${_isPaid ? "Paid Online" : "Pay at Counter"})', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                const SizedBox(height: 4),
                Text('Deliver to: Room ${student.roomNo}, Hostel 4', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
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
                  context.pop();
                },
                child: const Text('VIEW STATUS', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const Text('SELECT AVAILABLE SPECIAL FOOD ITEM', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.black87, letterSpacing: 0.5)),
          const SizedBox(height: 8),

          Column(
            children: kAvailableSpecialFoods.map((item) {
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
                        child: Icon(item.icon, color: isSelected ? Colors.white : const Color(0xFFE65100), size: 22),
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
                                Text('₹${item.price}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1B5E20))),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(item.hindiName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            const SizedBox(height: 2),
                            Text(item.description, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700)),
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
                    const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
                    const Text('Total Bill Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('₹$totalBill', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFFE65100))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pay Online (UPI)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        value: true,
                        groupValue: _isPaid,
                        onChanged: (val) => setState(() => _isPaid = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pay on Delivery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        value: false,
                        groupValue: _isPaid,
                        onChanged: (val) => setState(() => _isPaid = val!),
                      ),
                    ),
                  ],
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
              label: Text(_isSubmitting ? 'PLACING ORDER...' : 'PAY ₹$totalBill & PLACE ORDER', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              onPressed: _isSubmitting ? null : _placeOrder,
            ),
          ),
        ],
      ),
    );
  }
}
