import 'package:flutter/material.dart';

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All Days';

  // Sample Month Ledger Data for August 2026 (Days 1 to 24)
  final List<DailyMealRecord> monthRecords = List.generate(24, (index) {
    final dayNum = index + 1;
    final date = DateTime(2026, 8, dayNum);
    final isSunday = date.weekday == DateTime.sunday;
    final isWednesday = date.weekday == DateTime.wednesday;

    // 5 mess-offs on specific days (8, 9, 15, 16, 22)
    final isOffDay = [8, 9, 15, 16, 22].contains(dayNum);

    final breakfastEaten = !isSunday && !isOffDay;
    final lunchEaten = !isOffDay;
    final dinnerEaten = !isOffDay;

    final bPrice = isSunday ? 0 : 25;
    final lPrice = isSunday ? 100 : 50;
    final dPrice = isWednesday ? 100 : 50;

    final dayTotal = (breakfastEaten ? bPrice : 0) +
        (lunchEaten ? lPrice : 0) +
        (dinnerEaten ? dPrice : 0);

    return DailyMealRecord(
      dayNum: dayNum,
      date: date,
      dayHindi: _getDayHindi(date.weekday),
      dayEnglish: _getDayEnglish(date.weekday),
      isSunday: isSunday,
      isWednesday: isWednesday,
      isMessOffDay: isOffDay,
      breakfastEaten: breakfastEaten,
      lunchEaten: lunchEaten,
      dinnerEaten: dinnerEaten,
      breakfastPrice: bPrice,
      lunchPrice: lPrice,
      dinnerPrice: dPrice,
      dayTotalCost: dayTotal,
    );
  });

  static String _getDayHindi(int weekday) {
    switch (weekday) {
      case 1: return 'सोमवार';
      case 2: return 'मंगलवार';
      case 3: return 'बुधवार';
      case 4: return 'गुरुवार';
      case 5: return 'शुक्रवार';
      case 6: return 'शनिवार';
      default: return 'रविवार';
    }
  }

  static String _getDayEnglish(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      default: return 'Sun';
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final totalEatenMeals = monthRecords.fold<int>(0, (sum, r) =>
        sum + (r.breakfastEaten ? 1 : 0) + (r.lunchEaten ? 1 : 0) + (r.dinnerEaten ? 1 : 0));
    final totalMessOffDays = monthRecords.where((r) => r.isMessOffDay).length;
    final totalMonthAmount = monthRecords.fold<int>(0, (sum, r) => sum + r.dayTotalCost);
    final totalWaiverSaved = totalMessOffDays * 125; // ₹125/day saved

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text('Monthly Mess Bill', style: TextStyle(fontWeight: FontWeight.bold)),
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
          // TAB 1: MONTHLY BILL STATEMENT & PREPAID DEPOSIT BREAKDOWN
          _buildMonthlyStatementTab(totalEatenMeals, totalMessOffDays, totalMonthAmount, totalWaiverSaved),

          // TAB 2: DAILY ATTENDANCE & CONSUMPTION CALENDAR LOG
          _buildDailyAttendanceTab(totalEatenMeals, totalMessOffDays, totalMonthAmount),
        ],
      ),
    );
  }

  // TAB 1: MONTHLY STATEMENT (PREPAID DEPOSIT CONSUMPTION - NO PAY OPTION)
  Widget _buildMonthlyStatementTab(int totalEatenMeals, int totalMessOffDays, int totalMonthAmount, int totalWaiverSaved) {
    const int semesterDeposit = 24000;
    const int priorMonthsTotal = 6300; // May + June
    final int currentTotalDeducted = priorMonthsTotal + totalMonthAmount;
    final int remainingBalance = semesterDeposit - currentTotalDeducted;

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
                color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
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
                  const Text('AUGUST 2026 STATEMENT', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
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
                'Total monthly mess fee deducted for August ($totalEatenMeals meals)',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mess-Off Savings Credited', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('₹$totalWaiverSaved Saved ($totalMessOffDays Days)', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade400.withValues(alpha: 0.22),
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

        // 2. Prepaid Deposit & Balance Summary
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
                  Icon(Icons.account_balance_wallet, color: Color(0xFF1B5E20), size: 18),
                  SizedBox(width: 8),
                  Text('Semester Prepaid Deposit Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your mess fee was deposited in advance. As you consume meals, the amount is deducted automatically.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
              ),
              const SizedBox(height: 14),
              _ledgerRow('Initial 6-Month Advance Deposit', '₹$semesterDeposit', Colors.black87),
              _ledgerRow('Prior Months Consumed (May–Jul)', '-₹$priorMonthsTotal', Colors.red.shade700),
              _ledgerRow('Current Month Consumed (Aug 2026)', '-₹$totalMonthAmount', Colors.red.shade700),
              _ledgerRow('Mess-Off Rebate Credits', '+₹$totalWaiverSaved', const Color(0xFF1B5E20)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Remaining Deposit Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    '₹$remainingBalance',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1B5E20)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Tariff Rules Info
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
              _tariffRow('🌅 Breakfast (Mon–Sat)', '₹25 / meal'),
              _tariffRow('🌅 Sunday Breakfast', 'No Breakfast (Mess Closed)'),
              _tariffRow('☀️ Regular Lunch (Mon–Sat)', '₹50 / meal'),
              _tariffRow('☀️ Sunday Special Feast Lunch', '₹100 / meal (Chicken/Mushroom & Sweet)'),
              _tariffRow('🌙 Regular Dinner (6 days)', '₹50 / meal'),
              _tariffRow('🌙 Wednesday Non-Veg Dinner', '₹100 / meal (Chicken / Paneer)'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Previous Monthly Statements Archive
        const Text('Previous Monthly Statements Archive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        _historyTile('July 2026', '76 meals consumed • 4 mess-offs', '₹3,250', 'Deducted from Deposit'),
        _historyTile('June 2026', '71 meals consumed • 6 mess-offs', '₹3,050', 'Deducted from Deposit'),
        _historyTile('May 2026', '82 meals consumed • 2 mess-offs', '₹3,500', 'Deducted from Deposit'),
      ],
    );
  }

  // TAB 2: DAILY ATTENDANCE & CONSUMPTION CALENDAR LOG
  Widget _buildDailyAttendanceTab(int totalEatenMeals, int totalMessOffDays, int totalAmount) {
    final filtered = monthRecords.where((r) {
      if (_selectedFilter == 'Eaten Only') return !r.isMessOffDay;
      if (_selectedFilter == 'Mess-Off Only') return r.isMessOffDay;
      return true;
    }).toList();

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
                  _statBadge('Days Tracked', '24 Days', Colors.blue),
                  const SizedBox(width: 8),
                  _statBadge('Meals Consumed', '$totalEatenMeals Meals', const Color(0xFF1B5E20)),
                  const SizedBox(width: 8),
                  _statBadge('Mess-Off Days', '$totalMessOffDays Days', Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              // Filter Chips
              Row(
                children: [
                  const Text('Filter: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(width: 6),
                  _filterChip('All Days'),
                  const SizedBox(width: 6),
                  _filterChip('Eaten Only'),
                  const SizedBox(width: 6),
                  _filterChip('Mess-Off Only'),
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
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final record = filtered[index];
              return _buildDayCard(record);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(DailyMealRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: r.isMessOffDay ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Date Box
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: r.isMessOffDay ? Colors.orange.shade50 : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: r.isMessOffDay ? Colors.orange.shade200 : const Color(0xFFA5D6A7)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${r.dayNum}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: r.isMessOffDay ? Colors.orange.shade900 : const Color(0xFF1B5E20))),
                Text(r.dayEnglish, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: r.isMessOffDay ? Colors.orange.shade700 : const Color(0xFF2E7D32))),
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
                    Text('Aug ${r.dayNum} (${r.dayHindi})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                if (r.isMessOffDay)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange.shade200)),
                        child: const Text('MESS-OFF (₹125 Waived)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10.5)),
                      ),
                    ],
                  )
                else
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
                r.isMessOffDay ? '₹0' : '₹${r.dayTotalCost}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: r.isMessOffDay ? Colors.grey : const Color(0xFF1B5E20),
                ),
              ),
              Text(
                r.isMessOffDay ? 'Waived' : 'Deducted',
                style: TextStyle(fontSize: 10, color: r.isMessOffDay ? Colors.orange : Colors.grey),
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
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isEaten ? const Color(0xFF1B5E20) : Colors.grey)),
        ],
      ),
    );
  }

  Widget _filterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade300),
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _ledgerRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _tariffRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        ],
      ),
    );
  }

  Widget _historyTile(String month, String details, String amount, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              Text(month, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(details, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
              Text(status, style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20))),
        ],
      ),
    );
  }
}

class DailyMealRecord {
  final int dayNum;
  final DateTime date;
  final String dayHindi;
  final String dayEnglish;
  final bool isSunday;
  final bool isWednesday;
  final bool isMessOffDay;
  final bool breakfastEaten;
  final bool lunchEaten;
  final bool dinnerEaten;
  final int breakfastPrice;
  final int lunchPrice;
  final int dinnerPrice;
  final int dayTotalCost;

  DailyMealRecord({
    required this.dayNum,
    required this.date,
    required this.dayHindi,
    required this.dayEnglish,
    required this.isSunday,
    required this.isWednesday,
    required this.isMessOffDay,
    required this.breakfastEaten,
    required this.lunchEaten,
    required this.dinnerEaten,
    required this.breakfastPrice,
    required this.lunchPrice,
    required this.dinnerPrice,
    required this.dayTotalCost,
  });
}
