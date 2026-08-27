import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/events_provider.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  String selectedFilter = 'All';

  void _applyMessOffForEvent(BuildContext context, CollegeEvent event) {
    final startStr = DateFormat('dd MMM yyyy').format(event.date);
    final endStr = event.endDate != null ? DateFormat('dd MMM yyyy').format(event.endDate!) : startStr;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.event_busy, color: Colors.orange, size: 22),
            ),
            const SizedBox(width: 8),
            const Text('Apply Mess-Off', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event: ${event.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
            const SizedBox(height: 6),
            Text('Duration: $startStr to $endStr', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF1B5E20), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mess fee will be waived automatically at ₹125/day for approved mess-off dates.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/mess-off');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mess-off request queued for "${event.title}"!'),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('CONFIRM MESS-OFF', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsListProvider);
    final events = eventsAsync.valueOrNull ?? [];
    final filteredEvents = selectedFilter == 'All'
        ? events
        : events.where((e) => e.category == selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: const Text('Institute Events & Mess Advisories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top Summary Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E5D2A), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E20).withOpacity(0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.campaign, color: Colors.amberAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Plan Your Meals & Mess-Offs in Advance',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upcoming exams, vacations, and campus festivals are published here by the administration to help you plan mess-off leaves and save on monthly billing.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Events Feed
          ...filteredEvents.map((item) {
            final dateStr = DateFormat('dd MMM yyyy').format(item.date);
            final endStr = item.endDate != null ? ' - ${DateFormat('dd MMM yyyy').format(item.endDate!)}' : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: item.borderColor.withOpacity(0.6), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag & Date Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: item.borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(item.icon, size: 13, color: item.tagColor),
                              const SizedBox(width: 5),
                              Text(
                                item.category.toUpperCase(),
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: item.tagColor),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.impactLevel == 'High' ? Colors.red.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: item.impactLevel == 'High' ? Colors.red.shade200 : Colors.blue.shade200,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${item.impactLevel} Turnout Impact',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.impactLevel == 'High' ? Colors.red.shade800 : Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$dateStr$endStr',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                    ),
                    const SizedBox(height: 12),

                    // Advisory Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tips_and_updates_outlined, size: 13, color: Color(0xFFE65100)),
                              const SizedBox(width: 5),
                              Text('ADVISORY & MESS UPDATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.orange.shade900)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(item.advisory, style: TextStyle(fontSize: 11.5, color: Colors.orange.shade900, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action Button to Apply Mess-Off
                    if (item.category == 'Holiday' || item.impactLevel == 'High')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.event_busy, size: 16),
                          label: const Text('APPLY MESS-OFF FOR THIS VACATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _applyMessOffForEvent(context, item),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class CollegeEvent {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final String description;
  final String messImpact;
  final String impactLevel;
  final Color tagColor;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final String advisory;

  const CollegeEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.endDate,
    required this.location,
    required this.description,
    required this.messImpact,
    required this.impactLevel,
    required this.tagColor,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.advisory,
  });
}
