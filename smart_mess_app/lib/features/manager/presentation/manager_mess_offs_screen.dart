import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagerMessOffsScreen extends ConsumerStatefulWidget {
  const ManagerMessOffsScreen({super.key});

  @override
  ConsumerState<ManagerMessOffsScreen> createState() => _ManagerMessOffsScreenState();
}

class _ManagerMessOffsScreenState extends ConsumerState<ManagerMessOffsScreen> {
  String _searchQuery = '';
  String _selectedMealFilter = 'All';
  List<Map<String, dynamic>> _messOffs = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchMessOffs();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchMessOffs(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMessOffs({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final res = await dio.post(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'structuredQuery': {
            'from': [{'collectionId': 'messOffs'}]
          }
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && res.data is List) {
        final List data = res.data;
        final list = <Map<String, dynamic>>[];

        for (final item in data) {
          if (item is Map && item['document'] != null) {
            final doc = item['document'] as Map;
            final fields = (doc['fields'] as Map?) ?? {};
            final docName = (doc['name'] as String? ?? '').split('/').isNotEmpty ? (doc['name'] as String? ?? '').split('/').last : '';

            list.add({
              'id': fields['id']?['stringValue'] ?? docName,
              'studentName': fields['studentName']?['stringValue'] ?? 'Resident',
              'registrationNo': fields['registrationNo']?['stringValue'] ?? fields['studentId']?['stringValue'] ?? '',
              'rollNo': fields['rollNo']?['stringValue'] ?? '',
              'roomNo': fields['roomNo']?['stringValue'] ?? '101',
              'mealType': fields['mealType']?['stringValue'] ?? 'Lunch',
              'date': fields['date']?['stringValue'] ?? fields['createdAt']?['stringValue'] ?? '',
              'reason': fields['reason']?['stringValue'] ?? 'Personal leave',
              'status': fields['status']?['stringValue'] ?? 'Active',
              'refundCredited': fields['refundCredited']?['booleanValue'] ?? true,
            });
          }
        }

        list.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
        if (mounted) {
          setState(() {
            _messOffs = list;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _messOffs.where((item) {
      final name = (item['studentName'] ?? '').toString().toLowerCase();
      final reg = (item['registrationNo'] ?? item['studentId'] ?? item['rollNo'] ?? '').toString().toLowerCase();
      final meal = (item['mealType'] ?? '').toString();

      final matchesQuery = _searchQuery.isEmpty || name.contains(_searchQuery) || reg.contains(_searchQuery);
      final matchesMeal = _selectedMealFilter == 'All' || meal.toLowerCase().contains(_selectedMealFilter.toLowerCase());

      return matchesQuery && matchesMeal;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Mess-Off Exemption Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchMessOffs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by Student Name or Reg No...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF1B5E20)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 8),
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

          // Real-time Mess-Off records stream with timeout guard
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available, size: 64, color: Colors.green.shade300),
                            const SizedBox(height: 12),
                            Text('No Mess-Off Requests Recorded', style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('When students opt-out before cutoff, details appear here in real time.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchMessOffs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final name = item['studentName'] ?? 'Student';
                            final regNo = item['registrationNo'] ?? item['studentId'] ?? item['rollNo'] ?? '';
                            final room = item['roomNo'] ?? '101';
                            final meal = item['mealType'] ?? 'Lunch';
                            final reason = item['reason'] ?? 'Exemption';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFFCC80), width: 1),
                                boxShadow: [
                                  BoxShadow(color: Colors.orange.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.event_busy, color: Color(0xFFE65100), size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5), overflow: TextOverflow.ellipsis),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.orange.shade200),
                                              ),
                                              child: Text(meal, style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text('Reg: $regNo • Room $room', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                        const SizedBox(height: 2),
                                        Text('Reason: $reason', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('₹50', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1B5E20))),
                                      const Text('Rebate', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
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
    );
  }
}
