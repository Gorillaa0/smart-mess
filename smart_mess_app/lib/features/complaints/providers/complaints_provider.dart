import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/services/firestore_service.dart';

final complaintsListProvider = FutureProvider<List<ComplaintModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return [
    ComplaintModel(
      id: '1',
      studentId: '123',
      category: 'Food Quality',
      description: 'The rice was undercooked today.',
      status: 'in_progress',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      response: 'We apologize. Staff has been warned.',
    ),
  ];
});

class SubmitComplaintNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _db;

  SubmitComplaintNotifier(this._db) : super(const AsyncData(null));

  Future<void> submitComplaint(ComplaintModel complaint) async {
    state = const AsyncLoading();
    try {
      await _db.addDocument('complaints', complaint.toMap());
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final submitComplaintProvider = StateNotifierProvider<SubmitComplaintNotifier, AsyncValue<void>>((ref) {
  return SubmitComplaintNotifier(ref.watch(firestoreServiceProvider));
});
