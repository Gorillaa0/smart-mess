import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/h4_students_data.dart';

class ManagerAttendanceScreen extends ConsumerStatefulWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  ConsumerState<ManagerAttendanceScreen> createState() => _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState extends ConsumerState<ManagerAttendanceScreen> {
  String _selectedMeal = 'Lunch';
  String _selectedStatusFilter = 'All';
  String _selectedBranch = 'All';
  String _searchQuery = '';

  // Local simulated state for 112 students
  late Map<String, _MealRecord> _attendanceMap;

  @override
  void initState() {
    super.initState();
    _attendanceMap = {};
    for (int i = 0; i < H4StudentDirectory.students.length; i++) {
      final s = H4StudentDirectory.students[i];
      if (i < 76) {
        final min = 10 + (i % 45);
        _attendanceMap[s.registrationNo] = _MealRecord(
          status: 'present',
          time: '01:${min < 10 ? '0' + min.toString() : min} PM',
          token: 'H4-L-${8100 + i}',
        );
      } else if (i < 94) {
        _attendanceMap[s.registrationNo] = _MealRecord(
          status: 'mess-off',
        );
      } else {
        _attendanceMap[s.registrationNo] = _MealRecord(
          status: 'absent',
        );
      }
    }
  }

  void _toggleStudent(H4Student student) {
    final cur = _attendanceMap[student.registrationNo]?.status ?? 'absent';
    final next = cur == 'present' ? 'absent' : 'present';
    final nowTime = TimeOfDay.now().format(context);

    setState(() {
      _attendanceMap[student.registrationNo] = _MealRecord(
        status: next,
        time: next == 'present' ? nowTime : null,
        token: next == 'present' ? 'H4-L-${student.registrationNo.substring(student.registrationNo.length - 4)}' : null,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next == 'present'
              ? 'Marked ${student.name} as PRESENT & EATEN'
              : 'Marked ${student.name} as ABSENT',
        ),
        backgroundColor: next == 'present' ? const Color(0xFF2E7D32) : Colors.orange.shade800,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = H4StudentDirectory.students;
    final presentCount = _attendanceMap.values.where((v) => v.status == 'present').length;
    final messOffCount = _attendanceMap.values.where((v) => v.status == 'mess-off').length;
    final absentCount = _attendanceMap.values.where((v) => v.status == 'absent').length;

    final filtered = students.where((s) {
      final rec = _attendanceMap[s.registrationNo] ?? _MealRecord(status: 'absent');
      final matchesStatus = _selectedStatusFilter == 'All' || rec.status == _selectedStatusFilter.toLowerCase();
      final matchesBranch = _selectedBranch == 'All' || s.branch == _selectedBranch;
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.rollNo.toLowerCase().contains(q) ||
          s.registrationNo.contains(q) ||
          s.roomNo.contains(q);

      return matchesStatus && matchesBranch && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: const Text('Student Meal Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top Meal Session Selector
          Container(
            color: const Color(0xFF1B5E20),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: ['Breakfast', 'Lunch', 'Dinner'].map((meal) {
                final isSel = _selectedMeal == meal;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMeal = meal),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          meal,
                          style: TextStyle(
                            color: isSel ? const Color(0xFF1B5E20) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Summary Stats Strip
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge('Present', '$presentCount/112', const Color(0xFF2E7D32), Icons.check_circle),
                _buildStatBadge('Mess-Off', '$messOffCount', Colors.orange.shade800, Icons.event_busy),
                _buildStatBadge('Absent', '$absentCount', Colors.red.shade800, Icons.cancel),
              ],
            ),
          ),

          // Search Bar & Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search 112 students (Name, Room, Roll)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: ['All', 'Present', 'Mess-Off', 'Absent'].map((filter) {
                final isSel = _selectedStatusFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(filter, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.black87)),
                    selected: isSel,
                    selectedColor: const Color(0xFF1B5E20),
                    backgroundColor: Colors.white,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedStatusFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // 112 Student Attendance List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final s = filtered[index];
                final rec = _attendanceMap[s.registrationNo] ?? _MealRecord(status: 'absent');

                Color statusColor;
                String statusLabel;
                IconData statusIcon;

                if (rec.status == 'present') {
                  statusColor = const Color(0xFF2E7D32);
                  statusLabel = 'PRESENT â€¢ EATEN';
                  statusIcon = Icons.check_circle;
                } else if (rec.status == 'mess-off') {
                  statusColor = Colors.orange.shade800;
                  statusLabel = 'MESS-OFF (WAIVED)';
                  statusIcon = Icons.event_busy;
                } else {
                  statusColor = Colors.red.shade700;
                  statusLabel = 'ABSENT / NOT EATEN';
                  statusIcon = Icons.cancel;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.12),
                      child: Icon(statusIcon, color: statusColor, size: 22),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '#${s.slNo}. ${s.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 9.5),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 3),
                        Text(
                          'Room ${s.roomNo} â€¢ ${s.branch} â€¢ Roll: ${s.rollNo}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                        if (rec.status == 'present')
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Scanned at ${rec.time ?? '1:15 PM'} (${rec.token ?? 'Token #H4'})',
                              style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 10.5),
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        rec.status == 'present' ? Icons.undo : Icons.check,
                        color: rec.status == 'present' ? Colors.grey : const Color(0xFF1B5E20),
                        size: 20,
                      ),
                      tooltip: rec.status == 'present' ? 'Mark Absent' : 'Mark Eaten',
                      onPressed: () => _toggleStudent(s),
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

  Widget _buildStatBadge(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 9.5)),
          ],
        ),
      ],
    );
  }
}

class _MealRecord {
  final String status;
  final String? time;
  final String? token;

  _MealRecord({required this.status, this.time, this.token});
}
