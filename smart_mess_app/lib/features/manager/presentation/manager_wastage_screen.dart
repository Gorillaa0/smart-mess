import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManagerWastageScreen extends StatefulWidget {
  const ManagerWastageScreen({super.key});

  @override
  State<ManagerWastageScreen> createState() => _ManagerWastageScreenState();
}

class _ManagerWastageScreenState extends State<ManagerWastageScreen> {
  final _prepController = TextEditingController();
  final _actualController = TextEditingController();
  final _wasteController = TextEditingController();
  String _selectedMeal = 'Lunch';
  bool _isSaving = false;

  void _submitWastage() async {
    final prep = int.tryParse(_prepController.text.trim());
    final actual = int.tryParse(_actualController.text.trim());
    final waste = double.tryParse(_wasteController.text.trim());

    if (prep == null || actual == null || waste == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric values for all fields'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();

    try {
      final docRef = FirebaseFirestore.instance.collection('wastage').doc();
      await docRef.set({
        'id': docRef.id,
        'mealType': _selectedMeal,
        'date': DateFormat('yyyy-MM-dd').format(now),
        'preparedQuantity': prep,
        'actualAttendance': actual,
        'wastedQuantity': waste,
        'accuracy': ((1 - (waste / prep).abs()) * 100).clamp(0.0, 100.0).toStringAsFixed(1),
        'recordedAt': now.toIso8601String(),
      });

      _prepController.clear();
      _actualController.clear();
      _wasteController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wastage record saved & synchronized to Cloud Database!'), backgroundColor: Color(0xFF1B5E20)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save wastage: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Daily Food Wastage Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Input Form Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
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
                    Text('Record Post-Meal Audit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFC62828))),
                    Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['Breakfast', 'Lunch', 'Dinner'].map((m) {
                    final isSel = _selectedMeal == m;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(m),
                        selected: isSel,
                        selectedColor: const Color(0xFFC62828),
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                        onSelected: (val) {
                          if (val) setState(() => _selectedMeal = m);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _prepController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Prepared Food Portions / Qty',
                    hintText: 'e.g. 108',
                    prefixIcon: const Icon(Icons.soup_kitchen, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _actualController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Actual Diners / Consumed Portions',
                    hintText: 'e.g. 104',
                    prefixIcon: const Icon(Icons.people, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _wasteController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Wasted / Leftover Food (kg or Portions)',
                    hintText: 'e.g. 4.0',
                    prefixIcon: const Icon(Icons.delete_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check, size: 18),
                    label: Text(_isSaving ? 'SAVING...' : 'SAVE WASTAGE AUDIT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _isSaving ? null : _submitWastage,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Real-time Wastage History
          const Text('REAL-TIME WASTAGE AUDIT LOGS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87, letterSpacing: 0.5)),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('wastage').orderBy('recordedAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No wastage entries recorded yet', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final meal = data['mealType'] ?? 'Meal';
                  final date = data['date'] ?? '';
                  final prep = data['preparedQuantity'] ?? 0;
                  final actual = data['actualAttendance'] ?? 0;
                  final waste = data['wastedQuantity'] ?? 0;
                  final acc = data['accuracy'] ?? '100';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$meal Audit ($date)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87)),
                            const SizedBox(height: 3),
                            Text('Prep: $prep • Diners: $actual • Wastage: $waste kg', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                          child: Text('$acc% Acc', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 11)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
