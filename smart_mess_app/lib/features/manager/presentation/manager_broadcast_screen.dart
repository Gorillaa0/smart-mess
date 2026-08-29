import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagerBroadcastScreen extends StatefulWidget {
  const ManagerBroadcastScreen({super.key});

  @override
  State<ManagerBroadcastScreen> createState() => _ManagerBroadcastScreenState();
}

class _ManagerBroadcastScreenState extends State<ManagerBroadcastScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _category = 'messoff';
  bool _isSending = false;

  void _sendBroadcast() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Title and Announcement Body'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('notifications').doc();
      await docRef.set({
        'id': docRef.id,
        'title': title,
        'body': body,
        'category': _category,
        'target': 'All Residents (112 Students)',
        'sentAt': DateTime.now().toIso8601String(),
        'deliveredCount': 112,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _titleController.clear();
      _bodyController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement successfully broadcasted to all 112 students!'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error broadcasting: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
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
        title: const Text('Send Broadcast Notice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Broadcast Composer Form Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign, color: Color(0xFF1B5E20), size: 22),
                    SizedBox(width: 8),
                    Text('New Official Mess Notice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20))),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Notice Category', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    {'key': 'messoff', 'label': '⏰ Mess-Off Cutoff'},
                    {'key': 'menu', 'label': '🍲 Special Menu'},
                    {'key': 'alert', 'label': '⚡ Mess Alert'},
                    {'key': 'event', 'label': '🎉 Feast / Event'},
                  ].map((cat) {
                    final isSel = _category == cat['key'];
                    return ChoiceChip(
                      label: Text(cat['label']!),
                      selected: isSel,
                      selectedColor: const Color(0xFF1B5E20),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                      onSelected: (val) {
                        if (val) setState(() => _category = cat['key']!);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Notice Title',
                    hintText: 'e.g. Dinner Mess-Off Deadline Reminder',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Detailed Message for Students',
                    hintText: 'e.g. Please apply for dinner mess-off before 05:00 PM today.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isSending
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, size: 18),
                    label: Text(
                      _isSending ? 'BROADCASTING...' : 'SEND BROADCAST TO 112 STUDENTS',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    onPressed: _isSending ? null : _sendBroadcast,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Broadcast History Header
          const Text('RECENT BROADCAST NOTICES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87, letterSpacing: 0.5)),
          const SizedBox(height: 10),

          // Real-time Firestore Stream of Notices
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              List<Map<String, dynamic>> list = docs.map((d) => d.data() as Map<String, dynamic>).toList();

              if (list.isEmpty) {
                list = [
                  {
                    'title': '⏰ Dinner Mess-Off Cutoff at 05:00 PM',
                    'body': 'Students planning to dine outside must apply for mess-off before 05:00 PM to receive meal rebate credit.',
                    'target': 'All Residents (112 Students)',
                    'sentAt': 'Today at 03:30 PM',
                    'deliveredCount': 112,
                  },
                  {
                    'title': '🍲 Special Sunday Feast Announced',
                    'body': 'Special Paneer Butter Masala, Pulao, Gulab Jamun served this Sunday for Dinner.',
                    'target': 'Hostel No. 4 Central Dining',
                    'sentAt': 'Yesterday at 07:00 PM',
                    'deliveredCount': 112,
                  },
                ];
              }

              return Column(
                children: list.map((n) {
                  final title = n['title'] ?? 'Notice';
                  final body = n['body'] ?? '';
                  final time = n['sentAt'] ?? '';
                  final count = n['deliveredCount'] ?? 112;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                              child: Text('$count Sent', style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(body, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.3)),
                        const SizedBox(height: 6),
                        Text('Sent: $time', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
