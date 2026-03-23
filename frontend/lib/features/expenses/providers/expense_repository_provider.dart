import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/features/expenses/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(dioProvider));
});
