import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/bill_model.dart';


final billingListProvider = FutureProvider<List<BillModel>>((ref) async {
  // Simulating fetching bills
  await Future.delayed(const Duration(milliseconds: 800));
  return [
    BillModel(
      id: '1',
      studentId: '123',
      month: 'August 2024',
      baseFee: 3000,
      messOffDeductions: 300,
      extras: 150,
      totalAmount: 2850,
      status: 'unpaid',
    ),
    BillModel(
      id: '2',
      studentId: '123',
      month: 'July 2024',
      baseFee: 3000,
      messOffDeductions: 0,
      extras: 0,
      totalAmount: 3000,
      status: 'paid',
    ),
  ];
});
