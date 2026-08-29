import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  List<Map<String, dynamic>> _wastageLogs = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchWastage();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchWastage(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWastage({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final res = await dio.post(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'structuredQuery': {
            'from': [{'collectionId': 'wastage'}]
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
              'mealType': fields['mealType']?['stringValue'] ?? 'Lunch',
              'date': fields['date']?['stringValue'] ?? '',
              'preparedQuantity': int.tryParse(fields['preparedQuantity']?['integerValue'] ?? '0') ?? 0,
              'actualAttendance': int.tryParse(fields['actualAttendance']?['integerValue'] ?? '0') ?? 0,
              'wastedQuantity': double.tryParse(fields['wastedQuantity']?['doubleValue']?.toString() ?? fields['wastedQuantity']?['integerValue']?.toString() ?? '0') ?? 0.0,
              'accuracy': fields['accuracy']?['stringValue'] ?? '95.0',
              'recordedAt': fields['recordedAt']?['stringValue'] ?? '',
            });
          }
        }

        list.sort((a, b) => (b['recordedAt'] ?? '').compareTo(a['recordedAt'] ?? ''));
        if (mounted) {
          setState(() {
            _wastageLogs = list;
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
    final newId = 'WASTE_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final dio = Dio();
      await dio.patch(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/wastage/$newId?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'fields': {
            'id': {'stringValue': newId},
            'mealType': {'stringValue': _selectedMeal},
            'date': {'stringValue': DateFormat('yyyy-MM-dd').format(now)},
            'preparedQuantity': {'integerValue': prep.toString()},
            'actualAttendance': {'integerValue': actual.toString()},
            'wastedQuantity': {'doubleValue': waste},
            'accuracy': {'stringValue': ((1 - (waste / prep).abs()) * 100).clamp(0.0, 100.0).toStringAsFixed(1)},
            'recordedAt': {'stringValue': now.toIso8601String()},
          }
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      _prepController.clear();
      _actualController.clear();
      _wasteController.clear();
      _fetchWastage(silent: true);

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
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Post-Meal Wastage Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchWastage(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Audit Form Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_document, color: Color(0xFF1B5E20), size: 20),
                    SizedBox(width: 8),
                    Text('Record Post-Meal Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
                  ],
                ),
                const SizedBox(height: 14),

                // Meal Selector
                Row(
                  children: ['Breakfast', 'Lunch', 'Dinner'].map((meal) {
                    final isSel = _selectedMeal == meal;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(meal),
                        selected: isSel,
                        selectedColor: const Color(0xFF1B5E20),
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11.5),
                        onSelected: (val) {
                          if (val) setState(() => _selectedMeal = meal);
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
                    labelText: 'Prepared Portions / Quantity (e.g. 110)',
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
                    labelText: 'Actual Boarders Attended / Consumed (e.g. 108)',
                    prefixIcon: const Icon(Icons.people_outline, size: 20),
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

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF1B5E20))))
          else if (_wastageLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('No wastage entries recorded yet', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Submit post-meal records above to populate the log in real time', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          else
            ..._wastageLogs.map((item) {
              final meal = item['mealType'] ?? 'Lunch';
              final date = item['date'] ?? '';
              final prep = item['preparedQuantity'] ?? 0;
              final actual = item['actualAttendance'] ?? 0;
              final wasted = item['wastedQuantity'] ?? 0;
              final accuracy = item['accuracy'] ?? '0';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFC62828), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$meal Meal Audit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text('Prepared: $prep | Attended: $actual | Wasted: $wasted kg', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$accuracy%', style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
