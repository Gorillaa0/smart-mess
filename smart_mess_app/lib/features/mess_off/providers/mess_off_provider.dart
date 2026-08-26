import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/meal_model.dart';
import '../../../core/services/functions_service.dart';

// Dummy provider for UI testing
final messOffListProvider = FutureProvider<List<MealModel>>((ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return [
    MealModel(
      id: '1',
      title: 'Today Lunch',
      type: 'Lunch',
      items: 'Dal, Chawal, Roti, Sabzi',
      startTime: DateTime.now().add(const Duration(hours: 2)),
      endTime: DateTime.now().add(const Duration(hours: 4)),
    ),
  ];
});

class MessOffActionNotifier extends StateNotifier<AsyncValue<void>> {
  final FunctionsService _functionsService;

  MessOffActionNotifier(this._functionsService) : super(const AsyncData(null));

  Future<void> markMessOff(String mealId) async {
    state = const AsyncLoading();
    try {
      await _functionsService.markMessOff(mealId, DateTime.now().toIso8601String());
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final messOffActionProvider = StateNotifierProvider<MessOffActionNotifier, AsyncValue<void>>((ref) {
  return MessOffActionNotifier(ref.watch(functionsServiceProvider));
});
