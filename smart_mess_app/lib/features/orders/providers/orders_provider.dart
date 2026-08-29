import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/shared_orders_store.dart';

final studentOrdersListProvider = Provider<List<SharedOrderRecord>>((ref) {
  final student = ref.watch(currentStudentProvider);
  final allOrders = ref.watch(liveOrdersGlobalProvider);

  return allOrders.where((o) {
    return o.registrationNo == student.registrationNo ||
           o.rollNo == student.rollNo ||
           o.studentName == student.name;
  }).toList();
});
