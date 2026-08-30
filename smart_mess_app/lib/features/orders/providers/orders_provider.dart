import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/shared_orders_store.dart';

final studentOrdersListProvider = Provider<List<SharedOrderRecord>>((ref) {
  final student = ref.watch(currentStudentProvider);
  final allOrders = ref.watch(liveOrdersGlobalProvider);
  final effectiveOrders = allOrders.isNotEmpty ? allOrders : SharedOrdersStore.localOrders;

  return effectiveOrders.where((o) {
    return o.registrationNo.toLowerCase().trim() == student.registrationNo.toLowerCase().trim() ||
           o.rollNo.toLowerCase().trim() == student.rollNo.toLowerCase().trim() ||
           o.studentName.toLowerCase().trim() == student.name.toLowerCase().trim();
  }).toList();
});
