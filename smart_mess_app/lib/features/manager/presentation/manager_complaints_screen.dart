import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagerComplaintsScreen extends ConsumerStatefulWidget {
  const ManagerComplaintsScreen({super.key});

  @override
  ConsumerState<ManagerComplaintsScreen> createState() => _ManagerComplaintsScreenState();
}

class _ManagerComplaintsScreenState extends ConsumerState<ManagerComplaintsScreen> {
  String _selectedStatus = 'All';
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchComplaints(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchComplaints({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final res = await dio.post(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'structuredQuery': {
            'from': [{'collectionId': 'complaints'}]
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
              'title': fields['title']?['stringValue'] ?? fields['subject']?['stringValue'] ?? 'Mess Grievance',
              'description': fields['description']?['stringValue'] ?? fields['body']?['stringValue'] ?? '',
              'category': fields['category']?['stringValue'] ?? 'Food Quality',
              'status': fields['status']?['stringValue'] ?? 'Pending',
              'studentName': fields['studentName']?['stringValue'] ?? fields['userName']?['stringValue'] ?? 'Resident',
              'roomNo': fields['roomNo']?['stringValue'] ?? '101',
              'hostel': fields['hostel']?['stringValue'] ?? 'Hostel Number 4',
              'managerResponse': fields['managerResponse']?['stringValue'] ?? '',
              'createdAt': fields['createdAt']?['stringValue'] ?? '',
            });
          }
        }

        list.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
        if (mounted) {
          setState(() {
            _complaints = list;
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

  void _showResolutionDialog(BuildContext context, String complaintId, String title, String currentResponse) {
    final responseController = TextEditingController(text: currentResponse);
    String targetStatus = 'Resolved';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.rate_review, color: Color(0xFF1B5E20), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text('Respond to Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Issue: $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 12),
              const Text('Update Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              Row(
                children: ['In Progress', 'Resolved'].map((st) {
                  final isSel = targetStatus == st;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(st),
                      selected: isSel,
                      selectedColor: st == 'Resolved' ? const Color(0xFF1B5E20) : Colors.orange.shade800,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11.5),
                      onSelected: (val) {
                        if (val) setDialogState(() => targetStatus = st);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responseController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Manager Official Response / Action Taken',
                  hintText: 'e.g., Kitchen staff notified. Hygiene inspected.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final responseText = responseController.text.trim();
                Navigator.pop(dialogCtx);

                try {
                  final dio = Dio();
                  await dio.patch(
                    'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/complaints/$complaintId?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E&updateMask.fieldPaths=status&updateMask.fieldPaths=managerResponse&updateMask.fieldPaths=resolvedAt',
                    data: {
                      'fields': {
                        'status': {'stringValue': targetStatus},
                        'managerResponse': {'stringValue': responseText},
                        'resolvedAt': {'stringValue': DateTime.now().toIso8601String()},
                      }
                    },
                    options: Options(headers: {'Content-Type': 'application/json'}),
                  );

                  _fetchComplaints(silent: true);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Complaint status updated to "$targetStatus" and sent to student!'),
                        backgroundColor: const Color(0xFF1B5E20),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update complaint: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('SUBMIT RESPONSE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _complaints.where((c) {
      if (_selectedStatus == 'All') return true;
      return (c['status'] ?? '').toString().toLowerCase() == _selectedStatus.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Student Complaints & Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchComplaints(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Pending', 'In Progress', 'Resolved'].map((st) {
                  final isSelected = _selectedStatus == st;
                  final count = st == 'All' ? _complaints.length : _complaints.where((c) => (c['status'] ?? '').toString().toLowerCase() == st.toLowerCase()).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$st ($count)'),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1B5E20),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedStatus = st);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Real-time REST complaints stream with timeout guard
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                            const SizedBox(height: 12),
                            Text('No complaints matching "$_selectedStatus"',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Student feedback will appear here in real time', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchComplaints,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final complaint = filtered[index];
                            final id = complaint['id'] ?? '';
                            final title = complaint['title'] ?? 'Mess Grievance';
                            final desc = complaint['description'] ?? '';
                            final category = complaint['category'] ?? 'General';
                            final status = complaint['status'] ?? 'Pending';
                            final student = complaint['studentName'] ?? 'Resident';
                            final room = complaint['roomNo'] ?? '101';
                            final response = complaint['managerResponse'] ?? '';

                            Color statusColor = Colors.orange;
                            if (status == 'Resolved') statusColor = Colors.green;
                            if (status == 'In Progress') statusColor = Colors.blue;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: statusColor.withOpacity(0.4), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFA5D6A7)),
                                        ),
                                        child: Text(
                                          category,
                                          style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor.withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87),
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      desc,
                                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.3),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.person_pin, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Filed by $student (Room $room, H4)',
                                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (response.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F8E9),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFC8E6C9)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.reply, size: 16, color: Color(0xFF1B5E20)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Manager Action / Response:',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1B5E20)),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  response,
                                                  style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1B5E20),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.edit_note, size: 16),
                                      label: Text(
                                        response.isEmpty ? 'RESPOND' : 'UPDATE RESOLUTION',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                                      ),
                                      onPressed: () => _showResolutionDialog(context, id, title, response),
                                    ),
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
