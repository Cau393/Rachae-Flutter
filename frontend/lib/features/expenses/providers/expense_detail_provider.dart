import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/providers/expense_repository_provider.dart';

final expenseDetailProvider = FutureProvider.autoDispose
    .family<ExpenseDetailModel, String>((ref, expenseId) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.fetchExpenseDetail(expenseId);
});
