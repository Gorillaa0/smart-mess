import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerMessOffsScreen extends ConsumerStatefulWidget {
  const ManagerMessOffsScreen({super.key});

  @override
  ConsumerState<ManagerMessOffsScreen> createState() => _ManagerMessOffsScreenState();
}

class _ManagerMessOffsScreenState extends ConsumerState<ManagerMessOffsScreen> {
  String _selectedMealFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Mess-Off Requests (Hostel 4)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
      ),
      body: Column(
        children: [
          // Filter Row & Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Student Name or Reg No...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Breakfast', 'Lunch', 'Dinner'].map((meal) {
                      final isSelected = _selectedMealFilter == meal;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(meal),
                          selected: isSelected,
                          selectedColor: const Color(0xFF1B5E20),
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedMealFilter = meal);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Real-time Firestore stream of Mess-Offs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('messOffs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                }

                final docs = snapshot.data?.docs ?? [];
                final List<Map<String, dynamic>> items = docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id;
                  return data;
                }).toList();

                final filtered = items.where((item) {
                  final name = (item['studentName'] ?? '').toString().toLowerCase();
                  final reg = (item['registrationNo'] ?? item['studentId'] ?? item['rollNo'] ?? '').toString().toLowerCase();
                  final meal = (item['mealType'] ?? '').toString();

                  final matchesQuery = _searchQuery.isEmpty || name.contains(_searchQuery) || reg.contains(_searchQuery);
                  final matchesMeal = _selectedMealFilter == 'All' || meal.toLowerCase().contains(_selectedMealFilter.toLowerCase());

                  return matchesQuery && matchesMeal;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 64, color: Colors.green.shade400),
                        const SizedBox(height: 12),
                        Text('No active mess-off requests found', style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('All boarders are currently registered for meals', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final name = item['studentName'] ?? 'Student';
                    final reg = item['registrationNo'] ?? item['studentId'] ?? item['rollNo'] ?? '';
                    final meal = item['mealType'] ?? 'Meal';
                    final date = item['date'] ?? '';
                    final refund = item['refundCredited'] ?? 50;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFCDD2), width: 1.1),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.no_food, color: Color(0xFFC62828), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text('Reg: $reg • $meal ($date)', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Text('Rebate: ₹$refund', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), fontSize: 11.5)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
