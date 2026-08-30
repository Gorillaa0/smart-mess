import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/h4_students_data.dart';
import '../../attendance/providers/attendance_provider.dart';

class ManagerAttendanceScreen extends ConsumerStatefulWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  ConsumerState<ManagerAttendanceScreen> createState() => _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState extends ConsumerState<ManagerAttendanceScreen> {
  String _selectedMeal = 'All';
  String _selectedStatusFilter = 'All';
  String _selectedBranch = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // 1. Live attendance scans from Firestore via liveAttendanceProvider
    final liveScans = ref.watch(liveAttendanceProvider);
    final now = DateTime.now();

    // Map registration numbers to live scan records for today
    final Map<String, H4MealScanRecord> presentMap = {};
    for (final scan in liveScans) {
      if (scan.scannedAt.year == now.year &&
          scan.scannedAt.month == now.month &&
          scan.scannedAt.day == now.day) {
        if (_selectedMeal == 'All' || scan.mealType.toLowerCase().contains(_selectedMeal.toLowerCase())) {
          presentMap[scan.registrationNo] = scan;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Attendance Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.green, size: 9),
                const SizedBox(width: 4),
                Text('${presentMap.length}/${H4StudentDirectory.students.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1B5E20))),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search 112 students by Name, Roll or Reg...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Status Filters
                      _buildChip('All (${H4StudentDirectory.students.length})', _selectedStatusFilter == 'All', () => setState(() => _selectedStatusFilter = 'All')),
                      _buildChip('Present (${presentMap.length})', _selectedStatusFilter == 'Present', () => setState(() => _selectedStatusFilter = 'Present'), color: Colors.green),
                      _buildChip('Remaining (${H4StudentDirectory.students.length - presentMap.length})', _selectedStatusFilter == 'Remaining', () => setState(() => _selectedStatusFilter = 'Remaining'), color: Colors.orange),
                      const SizedBox(width: 8),
                      // Meal Filter
                      DropdownButton<String>(
                        value: _selectedMeal,
                        underline: const SizedBox(),
                        items: ['All', 'Breakfast', 'Lunch', 'Dinner'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedMeal = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Students Roster List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: H4StudentDirectory.students.length,
              itemBuilder: (context, index) {
                final student = H4StudentDirectory.students[index];
                final scan = presentMap[student.registrationNo];
                final isPresent = scan != null;

                // Apply Filters
                if (_selectedStatusFilter == 'Present' && !isPresent) return const SizedBox();
                if (_selectedStatusFilter == 'Remaining' && isPresent) return const SizedBox();
                if (_searchQuery.isNotEmpty) {
                  final matchesName = student.name.toLowerCase().contains(_searchQuery);
                  final matchesRoll = student.rollNo.toLowerCase().contains(_searchQuery);
                  final matchesReg = student.registrationNo.toLowerCase().contains(_searchQuery);
                  if (!matchesName && !matchesRoll && !matchesReg) return const SizedBox();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isPresent ? const Color(0xFFA5D6A7) : Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isPresent ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                        child: Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPresent ? const Color(0xFF1B5E20) : Colors.grey)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87)),
                            const SizedBox(height: 2),
                            Text('Roll: ${student.rollNo} • Reg: ${student.registrationNo} • Room ${student.roomNo}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      if (isPresent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('VERIFIED', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w800, fontSize: 10)),
                              Text('${scan.scannedAt.hour.toString().padLeft(2, '0')}:${scan.scannedAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 9.5, color: Colors.green.shade800)),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: const Text('NOT SCANNED', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, {Color? color}) {
    final c = color ?? const Color(0xFF1B5E20);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? c : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11.5, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
