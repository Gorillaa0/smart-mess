import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../presentation/events_screen.dart';

class EventsNotifier extends StateNotifier<AsyncValue<List<CollegeEvent>>> {
  Timer? _pollTimer;

  EventsNotifier() : super(const AsyncLoading()) {
    _fetchLiveEvents();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchLiveEvents());
  }

  Future<void> _fetchLiveEvents() async {
    try {
      final dio = Dio();
      final res = await dio.post(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'structuredQuery': {
            'from': [{'collectionId': 'events'}]
          }
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200 && res.data is List) {
        final List results = res.data;
        final liveList = <CollegeEvent>[];

        for (final item in results) {
          if (item is Map && item['document'] != null) {
            final doc = item['document'] as Map;
            final fields = (doc['fields'] as Map?) ?? {};

            final id = fields['id']?['stringValue'] ?? (doc['name']?.toString().split('/').last ?? 'evt');
            final title = fields['title']?['stringValue'] ?? 'Campus Event';
            final type = fields['type']?['stringValue'] ?? 'Holiday';
            final startStr = fields['startDate']?['stringValue'] ?? '';
            final endStr = fields['endDate']?['stringValue'];
            final impact = fields['impactLevel']?['stringValue'] ?? 'Medium';
            final desc = fields['description']?['stringValue'] ?? '';
            final advisory = fields['advisoryForStudents']?['stringValue'] ?? fields['advisory']?['stringValue'] ?? '';
            final messImpact = fields['expectedMessOffs']?['stringValue'] ?? 'Normal dining schedule';

            final start = DateTime.tryParse(startStr) ?? DateTime.now();
            final end = endStr != null ? DateTime.tryParse(endStr) : null;

            Color tagCol;
            Color bgCol;
            Color borderCol;
            IconData ic;

            if (type.toLowerCase().contains('exam') || type.toLowerCase().contains('academic')) {
              tagCol = const Color(0xFF1565C0);
              bgCol = const Color(0xFFE3F2FD);
              borderCol = const Color(0xFF90CAF9);
              ic = Icons.menu_book;
            } else if (type.toLowerCase().contains('fest') || type.toLowerCase().contains('celebration')) {
              tagCol = const Color(0xFF6A1B9A);
              bgCol = const Color(0xFFF3E5F5);
              borderCol = const Color(0xFFCE93D8);
              ic = Icons.celebration;
            } else {
              tagCol = const Color(0xFFC62828);
              bgCol = const Color(0xFFFFEBEE);
              borderCol = const Color(0xFFEF9A9A);
              ic = Icons.holiday_village;
            }

            liveList.add(CollegeEvent(
              id: id,
              title: title,
              category: type,
              date: start,
              endDate: end,
              location: 'Hostel H4 / Campus',
              description: desc,
              messImpact: messImpact,
              impactLevel: impact,
              tagColor: tagCol,
              bgColor: bgCol,
              borderColor: borderCol,
              icon: ic,
              advisory: advisory,
            ));
          }
        }

        if (liveList.isNotEmpty) {
          liveList.sort((a, b) => a.date.compareTo(b.date));
          state = AsyncData(liveList);
          return;
        }
      }
    } catch (_) {}

    // Fallback default
    if (state is AsyncLoading) {
      state = AsyncData([
        CollegeEvent(
          id: 'evt_default_1',
          title: 'Mid-Semester Examinations (6th Sem)',
          category: 'Exam',
          date: DateTime.now().add(const Duration(days: 4)),
          endDate: DateTime.now().add(const Duration(days: 10)),
          location: 'Academic Complex',
          description: 'University theory examinations for all departments.',
          messImpact: '35% Higher Attendance in Mess (Night Snacks Active)',
          impactLevel: 'Medium',
          tagColor: const Color(0xFF1565C0),
          bgColor: const Color(0xFFE3F2FD),
          borderColor: const Color(0xFF90CAF9),
          icon: Icons.menu_book,
          advisory: 'Extended dining hours will be active. Night tea served.',
        ),
      ]);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final eventsListProvider = StateNotifierProvider<EventsNotifier, AsyncValue<List<CollegeEvent>>>((ref) {
  return EventsNotifier();
});
