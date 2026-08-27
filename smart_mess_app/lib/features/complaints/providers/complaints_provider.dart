import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/complaint_model.dart';

class ComplaintsNotifier extends StateNotifier<AsyncValue<List<ComplaintModel>>> {
  Timer? _pollTimer;

  ComplaintsNotifier() : super(const AsyncLoading()) {
    _fetchLive();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchLive());
  }

  Future<void> _fetchLive() async {
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
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200 && res.data is List) {
        final List results = res.data;
        final list = <ComplaintModel>[];

        for (final item in results) {
          if (item is Map && item['document'] != null) {
            final doc = item['document'] as Map;
            final fields = (doc['fields'] as Map?) ?? {};
            final id = fields['id']?['stringValue'] ?? (doc['name']?.toString().split('/').last ?? 'cmp');

            list.add(ComplaintModel.fromFirestoreJson(id, Map<String, dynamic>.from(fields)));
          }
        }

        // Sort newest first
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = AsyncData(list);
        return;
      }
    } catch (_) {}

    // Fallback if loading
    if (state is AsyncLoading) {
      state = AsyncData([
        ComplaintModel(
          id: 'cmp_sample_1',
          title: 'Undercooked Rice in Lunch',
          studentId: '21BCSE042',
          studentName: 'Priyanshu Sharma',
          hostelId: 'Hostel H4',
          roomNumber: '204',
          category: 'Food Quality',
          description: 'The plain rice served in lunch was hard and undercooked.',
          status: 'In Progress',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          response: 'Inspected kitchen. Cook instructed to recalibrate rice steamer timing.',
        ),
      ]);
    }
  }

  Future<bool> submitComplaint(ComplaintModel complaint) async {
    try {
      final dio = Dio();
      final res = await dio.patch(
        'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/complaints/${complaint.id}?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
        data: {
          'fields': complaint.toFirestoreFields(),
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (res.statusCode == 200) {
        // Optimistic update
        final current = state.valueOrNull ?? [];
        state = AsyncData([complaint, ...current]);
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final complaintsListProvider = StateNotifierProvider<ComplaintsNotifier, AsyncValue<List<ComplaintModel>>>((ref) {
  return ComplaintsNotifier();
});
