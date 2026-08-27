import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/weekly_menu.dart';
import '../../../core/router/app_router.dart';

class MessOffScreen extends ConsumerStatefulWidget {
  const MessOffScreen({super.key});

  @override
  ConsumerState<MessOffScreen> createState() => _MessOffScreenState();
}

class _MessOffScreenState extends ConsumerState<MessOffScreen> {
  DateTime _selectedDate = DateTime.now();
  Timer? _timer;

  // Map of (Date string YYYY-MM-DD + mealType) -> isMessOff
  final Map<String, bool> _messOffMap = {};

  @override
  void initState() {
    super.initState();
    _fetchLiveMessOffs();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _fetchLiveMessOffs() async {
    try {
      final student = ref.read(currentStudentProvider);
      final dio = Dio();
      final res = await dio.post(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'structuredQuery': {
            'from': [{'collectionId': 'messOffs'}]
          }
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200 && res.data is List) {
        final List results = res.data;
        for (final item in results) {
          if (item is Map && item['document'] != null) {
            final doc = item['document'] as Map;
            final fields = (doc['fields'] as Map?) ?? {};
            final reg = fields['registrationNo']?['stringValue'];
            if (reg == student.registrationNo) {
              final dateStr = fields['date']?['stringValue'] ?? '';
              final meal = fields['mealType']?['stringValue']?.toLowerCase() ?? '';
              if (dateStr.isNotEmpty && meal.isNotEmpty) {
                setState(() {
                  _messOffMap['${dateStr}_$meal'] = true;
                });
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getKey(DateTime date, String mealType) {
    return '${DateFormat('yyyy-MM-dd').format(date)}_$mealType';
  }

  bool _isMealOff(DateTime date, String mealType) {
    return _messOffMap[_getKey(date, mealType)] ?? false;
  }

  Future<void> _toggleMealOff(DateTime date, String mealType) async {
    final key = _getKey(date, mealType);
    final current = _messOffMap[key] ?? false;
    final next = !current;
    final student = ref.read(currentStudentProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final docId = 'MO_${student.rollNo}_${dateStr}_$mealType';

    setState(() {
      _messOffMap[key] = next;
    });

    try {
      final dio = Dio();
      if (next) {
        // Save to Firestore
        await dio.patch(
          'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/messOffs/$docId?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
          data: {
            'fields': {
              'id': {'stringValue': docId},
              'studentName': {'stringValue': student.name},
              'rollNo': {'stringValue': student.rollNo},
              'registrationNo': {'stringValue': student.registrationNo},
              'roomNo': {'stringValue': student.roomNo},
              'branch': {'stringValue': student.branch},
              'mealType': {'stringValue': mealType},
              'date': {'stringValue': dateStr},
              'requestedAt': {'stringValue': DateTime.now().toIso8601String()},
              'status': {'stringValue': 'Approved'},
              'refundCredited': {'integerValue': '50'},
            }
          },
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      } else {
        // Delete from Firestore
        await dio.delete(
          'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/messOffs/$docId?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        );
      }
    } catch (_) {}
  }

  bool _isCutoffPassed(DateTime date, int cutoffHour, int cutoffMinute) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate.isBefore(today)) return true; // Past day
    if (targetDate.isAfter(today)) return false;  // Future day -> Cutoff is in the future!

    // Same day: check current time vs cutoff time
    final cutoffDateTime = DateTime(now.year, now.month, now.day, cutoffHour, cutoffMinute);
    return now.isAfter(cutoffDateTime);
  }

  String _getCutoffStatus(DateTime date, int cutoffHour, int cutoffMinute, String cutoffTimeStr) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate.isBefore(today)) return 'Past Date (Locked)';
    if (targetDate.isAfter(today)) {
      return 'Advance Notice Open (Cutoff: $cutoffTimeStr on day)';
    }

    final cutoffDateTime = DateTime(now.year, now.month, now.day, cutoffHour, cutoffMinute);
    if (now.isAfter(cutoffDateTime)) {
      return 'Cutoff Closed ($cutoffTimeStr)';
    }
    final diff = cutoffDateTime.difference(now);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    if (hours > 0) return '$hours h $mins m left (Cutoff: $cutoffTimeStr)';
    return '$mins m ${diff.inSeconds % 60}s left';
  }

  @override
  Widget build(BuildContext context) {
    final targetMenu = WeeklyMenuData.getTodayMenu(_selectedDate);
    final now = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(now);
    final isFuture = _selectedDate.isAfter(DateTime(now.year, now.month, now.day));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text('Advance Mess-Off Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Pick Custom Date Range',
            onPressed: _pickCustomDateRange,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. DATE SELECTOR STRIP (Today, Tomorrow, Upcoming Days)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, size: 16, color: Color(0xFF1B5E20)),
                      SizedBox(width: 6),
                      Text(
                        'SELECT DAY FOR MESS-OFF',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1B5E20), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('dd MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(7, (index) {
                    final date = DateTime.now().add(Duration(days: index));
                    final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
                    final label = index == 0 ? 'Today' : (index == 1 ? 'Tomorrow' : DateFormat('E, dd').format(date));

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text(label),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        selectedColor: const Color(0xFF1B5E20),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade300),
                        ),
                        showCheckmark: false,
                        onSelected: (val) {
                          setState(() => _selectedDate = date);
                        },
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. DAY SUMMARY BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFuture
                    ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
                    : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${targetMenu.dayHindi.toUpperCase()} (${targetMenu.dayEnglish.toUpperCase()})',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isToday ? 'TODAY' : 'UPCOMING ADVANCE DAY',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isFuture ? 'Advance Notice: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}' : 'Today\'s Mess-Off Notice',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Opting out reduces kitchen food wastage & grants bill deduction on valid notice.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. MEAL SLOTS LIST FOR THE SELECTED DAY
          // Breakfast Card
          if (targetMenu.breakfast.isAvailable)
            _buildMealSlotCard(
              slot: targetMenu.breakfast,
              mealType: 'breakfast',
              color: Colors.amber.shade800,
            )
          else
            _buildSundayClosedCard(),
          const SizedBox(height: 14),

          // Lunch Card
          _buildMealSlotCard(
            slot: targetMenu.lunch,
            mealType: 'lunch',
            color: Colors.blue.shade800,
          ),
          const SizedBox(height: 14),

          // Dinner Card
          _buildMealSlotCard(
            slot: targetMenu.dinner,
            mealType: 'dinner',
            color: Colors.purple.shade800,
          ),
          const SizedBox(height: 20),

          // 4. OUTSTATION BULK LEAVE BANNER
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.luggage, color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Going Home / Outstation Leave?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Apply mess-off for multiple days in one click.', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _pickCustomDateRange,
                  child: const Text('DATE RANGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSlotCard({
    required MealSlot slot,
    required String mealType,
    required Color color,
  }) {
    final isOptedOut = _isMealOff(_selectedDate, mealType);
    final isPassed = _isCutoffPassed(_selectedDate, slot.cutoffHour, slot.cutoffMinute);
    final cutoffStatus = _getCutoffStatus(_selectedDate, slot.cutoffHour, slot.cutoffMinute, slot.cutoffTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOptedOut ? Colors.red.shade300 : Colors.grey.shade200,
          width: isOptedOut ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${slot.nameHindi} (${slot.nameEnglish})',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${slot.price}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isPassed ? Colors.red.shade200 : Colors.green.shade200, width: 0.8),
                ),
                child: Text(
                  cutoffStatus,
                  style: TextStyle(
                    color: isPassed ? Colors.red.shade800 : Colors.green.shade800,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dishes
          Text(slot.itemsHindi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(slot.itemsEnglish, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          const SizedBox(height: 14),

          // Status & Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isOptedOut ? Icons.cancel_outlined : Icons.check_circle_outline,
                    color: isOptedOut ? Colors.red : const Color(0xFF2E7D32),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOptedOut ? 'Status: Mess-Off Applied (Waiver ₹${slot.price})' : 'Status: Eating in Mess',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isOptedOut ? Colors.red.shade800 : const Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPassed
                      ? Colors.grey.shade400
                      : (isOptedOut ? Colors.grey.shade700 : Colors.red.shade700),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isPassed
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cutoff has passed at ${slot.cutoffTime} for this meal.'),
                            backgroundColor: Colors.red.shade800,
                          ),
                        );
                      }
                    : () {
                        _toggleMealOff(_selectedDate, mealType);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              !isOptedOut
                                  ? 'Marked Advance Mess-Off for ${slot.nameEnglish} (${DateFormat('dd MMM').format(_selectedDate)}).'
                                  : 'Cancelled Mess-Off for ${slot.nameEnglish}. You are registered to eat.',
                            ),
                            backgroundColor: !isOptedOut ? Colors.red.shade800 : const Color(0xFF2E7D32),
                          ),
                        );
                      },
                child: Text(
                  isPassed ? 'LOCKED' : (isOptedOut ? 'CANCEL OFF' : 'OPT OUT (OFF)'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSundayClosedCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '🌅 Sunday Breakfast is Closed (Mess Holiday). No mess-off required.',
              style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B5E20),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final daysCount = picked.end.difference(picked.start).inDays + 1;
      setState(() {
        for (int i = 0; i < daysCount; i++) {
          final d = picked.start.add(Duration(days: i));
          _messOffMap[_getKey(d, 'breakfast')] = true;
          _messOffMap[_getKey(d, 'lunch')] = true;
          _messOffMap[_getKey(d, 'dinner')] = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied Advance Outstation Mess-Off for $daysCount days (${DateFormat('dd MMM').format(picked.start)} - ${DateFormat('dd MMM').format(picked.end)})!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    }
  }
}
