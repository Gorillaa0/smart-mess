import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerComplaintsScreen extends ConsumerStatefulWidget {
  const ManagerComplaintsScreen({super.key});

  @override
  ConsumerState<ManagerComplaintsScreen> createState() => _ManagerComplaintsScreenState();
}

class _ManagerComplaintsScreenState extends ConsumerState<ManagerComplaintsScreen> {
  String _selectedStatus = 'All';

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
                  labelText: 'Manager Official Response',
                  hintText: 'e.g. Cook instructed to replace batch immediately.',
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
                final resp = responseController.text.trim();
                Navigator.pop(dialogCtx);

                try {
                  await FirebaseFirestore.instance.collection('complaints').doc(complaintId).set({
                    'status': targetStatus,
                    'response': resp,
                    'resolvedAt': targetStatus == 'Resolved' ? DateTime.now().toIso8601String() : null,
                    'updatedAt': DateTime.now().toIso8601String(),
                  }, SetOptions(merge: true));

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Complaint status marked as "$targetStatus" and response sent!'),
                        backgroundColor: const Color(0xFF1B5E20),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0.5,
        title: const Text('Student Complaints & Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
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
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(st),
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

          // Real-time Firestore stream (No fake dummy data)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                }

                final docs = snapshot.data?.docs ?? [];
                List<Map<String, dynamic>> list = docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id;
                  return data;
                }).toList();

                final filtered = list.where((c) {
                  if (_selectedStatus == 'All') return true;
                  return (c['status'] ?? '').toString().toLowerCase() == _selectedStatus.toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
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
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final title = item['title'] ?? item['category'] ?? 'Complaint';
                    final student = item['studentName'] ?? 'Student';
                    final room = item['roomNumber'] ?? item['roomNo'] ?? '101';
                    final desc = item['description'] ?? '';
                    final status = item['status'] ?? 'Pending';
                    final response = item['response'] ?? '';

                    Color statusColor = Colors.orange;
                    if (status == 'Resolved') statusColor = Colors.green;
                    if (status == 'Pending') statusColor = Colors.redAccent;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.black87)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withOpacity(0.4)),
                                ),
                                child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('By: $student (Room $room, Hostel H4)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3)),
                          if (response.toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFA5D6A7)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.reply, size: 16, color: Color(0xFF1B5E20)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text('Manager Response: $response', style: const TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1B5E20),
                                side: const BorderSide(color: Color(0xFF81C784)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              icon: const Icon(Icons.edit_note, size: 16),
                              label: const Text('Respond / Resolve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _showResolutionDialog(context, item['id'], title, response),
                            ),
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
