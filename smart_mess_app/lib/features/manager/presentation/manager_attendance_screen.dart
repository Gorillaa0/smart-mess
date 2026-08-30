import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/h4_students_data.dart';
import '../../attendance/providers/attendance_provider.dart';

class DailyStudentBillItem {
  final DateTime date;
  final String dayName;
  final String dateString;
  final bool isSunday;
  final bool isWednesday;
  final bool breakfastEaten;
  final bool lunchEaten;
  final bool dinnerEaten;
  final int breakfastPrice;
  final int lunchPrice;
  final int dinnerPrice;
  final int dayTotalCost;

  const DailyStudentBillItem({
    required this.date,
    required this.dayName,
    required this.dateString,
    required this.isSunday,
    required this.isWednesday,
    required this.breakfastEaten,
    required this.lunchEaten,
    required this.dinnerEaten,
    required this.breakfastPrice,
    required this.lunchPrice,
    required this.dinnerPrice,
    required this.dayTotalCost,
  });
}

class ManagerAttendanceScreen extends ConsumerStatefulWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  ConsumerState<ManagerAttendanceScreen> createState() => _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState extends ConsumerState<ManagerAttendanceScreen> {
  String _selectedMeal = 'All';
  String _selectedStatusFilter = 'Eaten (Present)';
  String _searchQuery = '';

  List<DailyStudentBillItem> _computeStudentDailyBill(List<H4MealScanRecord> scans, String regNo, String rollNo) {
    final cleanReg = regNo.trim();
    final cleanRoll = rollNo.trim();

    final studentScans = scans.where((s) {
      final sReg = s.registrationNo.trim();
      final sRoll = s.rollNo.trim();
      return sReg == cleanReg || sRoll == cleanReg || sReg == cleanRoll || sRoll == cleanRoll;
    }).toList();

    final Map<String, List<H4MealScanRecord>> scansByDate = {};
    for (final scan in studentScans) {
      final dateKey = DateFormat('yyyy-MM-dd').format(scan.scannedAt.toLocal());
      scansByDate.putIfAbsent(dateKey, () => []).add(scan);
    }

    final List<DailyStudentBillItem> records = [];

    scansByDate.forEach((dateKey, dayScans) {
      final date = DateTime.tryParse(dateKey) ?? DateTime.now();
      final isSunday = date.weekday == DateTime.sunday;
      final isWednesday = date.weekday == DateTime.wednesday;

      final breakfastEaten = dayScans.any((s) => s.mealType.toLowerCase().contains('breakfast'));
      final lunchEaten = dayScans.any((s) => s.mealType.toLowerCase().contains('lunch'));
      final dinnerEaten = dayScans.any((s) => s.mealType.toLowerCase().contains('dinner'));

      final bPrice = isSunday ? 0 : 25;
      final lPrice = isSunday ? 100 : 50;
      final dPrice = isWednesday ? 100 : 50;

      final dayTotal = (breakfastEaten ? bPrice : 0) +
          (lunchEaten ? lPrice : 0) +
          (dinnerEaten ? dPrice : 0);

      records.add(DailyStudentBillItem(
        date: date,
        dayName: DateFormat('EEEE').format(date),
        dateString: DateFormat('dd MMM yyyy').format(date),
        isSunday: isSunday,
        isWednesday: isWednesday,
        breakfastEaten: breakfastEaten,
        lunchEaten: lunchEaten,
        dinnerEaten: dinnerEaten,
        breakfastPrice: bPrice,
        lunchPrice: lPrice,
        dinnerPrice: dPrice,
        dayTotalCost: dayTotal,
      ));
    });

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  void _showStudentBillModal(BuildContext context, H4Student student, List<H4MealScanRecord> allScans) {
    final dailyRecords = _computeStudentDailyBill(allScans, student.registrationNo, student.rollNo);
    final totalMealsEaten = dailyRecords.fold<int>(
        0, (sum, r) => sum + (r.breakfastEaten ? 1 : 0) + (r.lunchEaten ? 1 : 0) + (r.dinnerEaten ? 1 : 0));
    final totalMonthAmount = dailyRecords.fold<int>(0, (sum, r) => sum + r.dayTotalCost);

    final breakfastScans = dailyRecords.where((r) => r.breakfastEaten).length;
    final lunchScans = dailyRecords.where((r) => r.lunchEaten).length;
    final dinnerScans = dailyRecords.where((r) => r.dinnerEaten).length;

    // Standard mess-off rebate calculation based on non-attended calendar days
    final int missedMeals = (dailyRecords.length * 3) - totalMealsEaten;
    final int messOffDeductions = (missedMeals * 40).clamp(0, 1200);
    final int advanceMessFee = student.depositedAmount; // Real advance mess deposit credited by student (₹10,000)
    final int balance = advanceMessFee - totalMonthAmount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Modal Handle & Header
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(
                        student.name.isNotEmpty ? student.name[0] : 'S',
                        style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('Roll: ${student.rollNo} • Reg: ${student.registrationNo}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                          Text('Hostel No. 4 • Room ${student.roomNo} (${student.branch})',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Bill Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    // Main Bill Amount Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('MONTHLY MESS BILL',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$totalMealsEaten Meals Eaten',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('₹$totalMonthAmount',
                                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 8),
                              const Text('total consumption', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Advance Deposit', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text('₹$advanceMessFee', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Mess-Off Rebate', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text('₹$messOffDeductions', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Net Balance', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text('₹$balance', style: TextStyle(color: balance >= 0 ? const Color(0xFFA5D6A7) : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Meal Type Breakdown
                    const Text('Meal Count & Rate Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMealSummaryChip(
                            'Breakfast',
                            '$breakfastScans',
                            '₹25 / meal',
                            Icons.wb_sunny_outlined,
                            const Color(0xFFE65100),
                            const Color(0xFFFFF3E0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMealSummaryChip(
                            'Lunch',
                            '$lunchScans',
                            '₹50 / ₹100',
                            Icons.restaurant,
                            const Color(0xFF1B5E20),
                            const Color(0xFFE8F5E9),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMealSummaryChip(
                            'Dinner',
                            '$dinnerScans',
                            '₹50 / ₹100',
                            Icons.nightlight_round,
                            const Color(0xFF1565C0),
                            const Color(0xFFE3F2FD),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Daily Consumption Log Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daily Verified Attendance & Billing Log',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${dailyRecords.length} days tracked',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (dailyRecords.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_outlined, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('No Attendance Scans Yet', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                            const SizedBox(height: 2),
                            Text('This student has not scanned for any meals this month.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    else
                      ...dailyRecords.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.dayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(item.dateString, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                                ],
                              ),
                              const Spacer(),
                              _buildMealStatusIcon('B', item.breakfastEaten, item.breakfastPrice),
                              const SizedBox(width: 6),
                              _buildMealStatusIcon('L', item.lunchEaten, item.lunchPrice),
                              const SizedBox(width: 6),
                              _buildMealStatusIcon('D', item.dinnerEaten, item.dinnerPrice),
                              const SizedBox(width: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('₹${item.dayTotalCost}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF1B5E20))),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealSummaryChip(String title, String count, String rate, IconData icon, Color primaryColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: primaryColor),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 6),
          Text('$count meals', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87)),
          Text(rate, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildMealStatusIcon(String label, bool eaten, int price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: eaten ? const Color(0xFF1B5E20) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${eaten ? "₹$price" : "—"}',
        style: TextStyle(
          color: eaten ? Colors.white : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 9.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Live attendance scans from Firestore
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

    // Filter students roster
    final List<H4Student> displayedStudents = H4StudentDirectory.students.where((student) {
      final scan = presentMap[student.registrationNo];
      final isPresent = scan != null;

      // Filter: Show only students who have eaten (Present) or based on status filter
      if (_selectedStatusFilter == 'Eaten (Present)' && !isPresent) return false;
      if (_selectedStatusFilter == 'Not Eaten' && isPresent) return false;

      // Search Query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = student.name.toLowerCase().contains(q);
        final matchesRoll = student.rollNo.toLowerCase().contains(q);
        final matchesReg = student.registrationNo.toLowerCase().contains(q);
        final matchesRoom = student.roomNo.toLowerCase().contains(q);
        if (!matchesName && !matchesRoll && !matchesReg && !matchesRoom) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Attendance & Bill Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.green, size: 9),
                const SizedBox(width: 5),
                Text('Eaten: ${presentMap.length}/${H4StudentDirectory.students.length}',
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
                    hintText: 'Search eaten students by Name, Roll or Reg...',
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
                      // Status Filters: Default is Eaten Only
                      _buildChip('Eaten Today (${presentMap.length})', _selectedStatusFilter == 'Eaten (Present)',
                          () => setState(() => _selectedStatusFilter = 'Eaten (Present)'),
                          color: const Color(0xFF1B5E20)),
                      _buildChip('All Students (${H4StudentDirectory.students.length})', _selectedStatusFilter == 'All',
                          () => setState(() => _selectedStatusFilter = 'All')),
                      _buildChip('Not Eaten (${H4StudentDirectory.students.length - presentMap.length})', _selectedStatusFilter == 'Not Eaten',
                          () => setState(() => _selectedStatusFilter = 'Not Eaten'),
                          color: Colors.orange),
                      const SizedBox(width: 8),
                      // Meal Filter
                      DropdownButton<String>(
                        value: _selectedMeal,
                        underline: const SizedBox(),
                        items: ['All', 'Breakfast', 'Lunch', 'Dinner']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12))))
                            .toList(),
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
            child: displayedStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          _selectedStatusFilter == 'Eaten (Present)'
                              ? 'No students scanned yet for this meal slot'
                              : 'No students found matching search',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text('Attendance records will appear here as students scan.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: displayedStudents.length,
                    itemBuilder: (context, index) {
                      final student = displayedStudents[index];
                      final scan = presentMap[student.registrationNo];
                      final isPresent = scan != null;

                      return InkWell(
                        onTap: () => _showStudentBillModal(context, student, liveScans),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isPresent ? const Color(0xFFA5D6A7) : Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isPresent ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                                child: Text('${index + 1}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isPresent ? const Color(0xFF1B5E20) : Colors.grey)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87)),
                                    const SizedBox(height: 2),
                                    Text('Roll: ${student.rollNo} • Reg: ${student.registrationNo} • Room ${student.roomNo}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // View Bill Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  foregroundColor: const Color(0xFF1B5E20),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.receipt_long, size: 14),
                                label: const Text('View Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                onPressed: () => _showStudentBillModal(context, student, liveScans),
                              ),
                            ],
                          ),
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
          child: Text(label,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
