import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/h4_students_data.dart';

class DailyBillRecord {
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

  const DailyBillRecord({
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

class BillScreen extends ConsumerStatefulWidget {
  const BillScreen({super.key});

  @override
  ConsumerState<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends ConsumerState<BillScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DailyBillRecord> _computeRealScanRecords(List<H4MealScanRecord> scans, String studentRegNo, String studentRollNo) {
    final cleanReg = studentRegNo.trim().toLowerCase();
    final cleanRoll = studentRollNo.trim().toLowerCase();
    final studentScans = scans.where((s) {
      final sr = s.registrationNo.trim().toLowerCase();
      final sl = s.rollNo.trim().toLowerCase();
      return sr == cleanReg || sr == cleanRoll || sl == cleanReg || sl == cleanRoll;
    }).toList();

    // Group actual student scans strictly by unique calendar dates
    final Map<String, List<H4MealScanRecord>> scansByDate = {};
    for (final scan in studentScans) {
      final dateKey = DateFormat('yyyy-MM-dd').format(scan.scannedAt.toLocal());
      scansByDate.putIfAbsent(dateKey, () => []).add(scan);
    }

    final List<DailyBillRecord> records = [];

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

      records.add(DailyBillRecord(
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

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProvider);
    final allScans = ref.watch(liveAttendanceProvider);
    final records = _computeRealScanRecords(allScans, student.registrationNo, student.rollNo);

    final totalEatenMeals = records.fold<int>(0, (sum, r) =>
        sum + (r.breakfastEaten ? 1 : 0) + (r.lunchEaten ? 1 : 0) + (r.dinnerEaten ? 1 : 0));
    final totalDaysTracked = records.length;
    final totalMonthAmount = records.fold<int>(0, (sum, r) => sum + r.dayTotalCost);

    final breakfastScans = records.where((r) => r.breakfastEaten).length;
    final lunchScans = records.where((r) => r.lunchEaten).length;
    final dinnerScans = records.where((r) => r.dinnerEaten).length;

    final currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text('Real-Time Mess Bill', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Monthly Statement', icon: Icon(Icons.receipt_long_outlined, size: 18)),
            Tab(text: 'Daily Meal Log', icon: Icon(Icons.fact_check_outlined, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: 100% REAL-TIME CONSUMPTION & ADVANCE DEPOSIT STATEMENT
          _buildMonthlyStatementTab(
            student,
            currentMonthName,
            totalEatenMeals,
            totalDaysTracked,
            totalMonthAmount,
            breakfastScans,
            lunchScans,
            dinnerScans,
          ),

          // TAB 2: VERIFIED DAILY ATTENDANCE & CONSUMPTION LOG
          _buildDailyAttendanceTab(
            totalEatenMeals,
            totalDaysTracked,
            totalMonthAmount,
            records,
          ),
        ],
      ),
    );
  }

  // TAB 1: 100% DYNAMIC MONTHLY STATEMENT WITH REAL ADVANCE DEPOSIT
  Widget _buildMonthlyStatementTab(
    H4Student student,
    String currentMonthName,
    int totalEatenMeals,
    int totalDaysTracked,
    int totalMonthAmount,
    int breakfastScans,
    int lunchScans,
    int dinnerScans,
  ) {
    final int advanceDeposit = student.depositedAmount; // Actual advance deposit credited by student (₹10,000)
    final int remainingBalance = advanceDeposit - totalMonthAmount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Current Month Consumption Hero Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E5D2A), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$currentMonthName STATEMENT',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Text('Prepaid Account', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '₹$totalMonthAmount',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                'Total mess charges deducted for $totalEatenMeals verified QR scans',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Remaining Deposit Balance', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(
                        '₹$remainingBalance Remaining',
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade400.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: const Text(
                      'AUTO-DEDUCTED',
                      style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w800, fontSize: 10.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Real Advance Deposit Ledger
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF1B5E20), size: 18),
                  SizedBox(width: 8),
                  Text('Prepaid Advance Deposit Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your advance mess deposit of ₹10,000. Meals consumed via QR scan are deducted automatically in real-time.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
              ),
              const SizedBox(height: 14),
              _ledgerRow('Initial Advance Deposit Paid', '₹$advanceDeposit', Colors.black87),
              _ledgerRow('Current Consumption Deducted', '-₹$totalMonthAmount', Colors.red.shade700),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Net Remaining Deposit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    '₹$remainingBalance',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1B5E20)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Real-Time Scan Itemization Breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.query_builder, color: Color(0xFF1B5E20), size: 18),
                  SizedBox(width: 8),
                  Text('Meal Consumption Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Itemized summary of meals physically scanned and verified at the counter.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
              ),
              const SizedBox(height: 14),
              _itemRow('Breakfast Scans', '$breakfastScans meals', '₹25 / scan'),
              _itemRow('Lunch Scans', '$lunchScans meals', '₹50 or ₹100'),
              _itemRow('Dinner Scans', '$dinnerScans meals', '₹50 or ₹100'),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Charges Deducted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    '₹$totalMonthAmount',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1B5E20)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Official Institutional Tariff Rules
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.sell_outlined, color: Color(0xFF1B5E20), size: 18),
                  SizedBox(width: 8),
                  Text('Hostel Number 4 Tariff Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              _tariffRow('Breakfast (Monday - Saturday)', '₹25 / meal'),
              _tariffRow('Sunday Breakfast', 'No Breakfast (Mess Closed)'),
              _tariffRow('Regular Lunch (Monday - Saturday)', '₹50 / meal'),
              _tariffRow('Sunday Special Feast Lunch', '₹100 / meal (Chicken/Mushroom & Sweet)'),
              _tariffRow('Regular Dinner (6 Days)', '₹50 / meal'),
              _tariffRow('Wednesday Non-Veg / Paneer Dinner', '₹100 / meal (Special Feast)'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Previous Monthly Statements Archive (Clean & Empty for New System)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Text('Previous Monthly Statements Archive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'No Previous Statements Archived',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This is your first active billing cycle starting from today.\nPast monthly statements will be archived here at the end of each month.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 2: VERIFIED DAILY ATTENDANCE & CONSUMPTION CALENDAR LOG
  Widget _buildDailyAttendanceTab(
    int totalEatenMeals,
    int totalDaysTracked,
    int totalAmount,
    List<DailyBillRecord> records,
  ) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: const Icon(Icons.qr_code_scanner, color: Color(0xFF1B5E20), size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Meal Scans Recorded Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 6),
              Text(
                'Once you scan the static counter QR code during meal times, your verified meals and daily billing log will appear here in real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Top Metric Banner
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  _statBadge('Days Tracked', '$totalDaysTracked Days', Colors.blue),
                  const SizedBox(width: 8),
                  _statBadge('Meals Consumed', '$totalEatenMeals Meals', const Color(0xFF1B5E20)),
                  const SizedBox(width: 8),
                  _statBadge('Total Charges', '₹$totalAmount', Colors.green.shade800),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Daily Attendance Scroll List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildDayCard(record);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(DailyBillRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Date Box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${r.date.day}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1B5E20)),
                ),
                Text(
                  DateFormat('MMM').format(r.date).toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Meal Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${r.dateString} (${r.dayName})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (r.isSunday)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Feast Day', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.brown)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (!r.isSunday)
                      _mealStatusPill('B: ₹${r.breakfastPrice}', r.breakfastEaten),
                    _mealStatusPill(r.isSunday ? 'L(Feast): ₹${r.lunchPrice}' : 'L: ₹${r.lunchPrice}', r.lunchEaten),
                    _mealStatusPill(r.isWednesday ? 'D(NonVeg): ₹${r.dinnerPrice}' : 'D: ₹${r.dinnerPrice}', r.dinnerEaten),
                  ],
                ),
              ],
            ),
          ),

          // Cost
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${r.dayTotalCost}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const Text(
                'Deducted',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mealStatusPill(String label, bool isEaten) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isEaten ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isEaten ? const Color(0xFFA5D6A7) : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isEaten ? Icons.check : Icons.close, size: 10, color: isEaten ? const Color(0xFF1B5E20) : Colors.grey),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isEaten ? const Color(0xFF1B5E20) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _ledgerRow(String label, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.black87), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(amount, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _itemRow(String title, String qty, String rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12.5, color: Colors.black87), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(qty, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(width: 6),
              Text('($rate)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tariffRow(String title, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 4,
            child: Text(
              price,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
          ),
        ],
      ),
    );
  }
}
