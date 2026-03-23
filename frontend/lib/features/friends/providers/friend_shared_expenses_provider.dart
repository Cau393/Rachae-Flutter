import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/expenses/models/expense_list_model.dart';
import 'package:frontend/features/friends/providers/friends_repository_provider.dart';

final friendSharedExpensesProvider =
    FutureProvider.autoDispose.family<List<ExpenseListModel>, String>(
  (ref, friendId) =>
      ref.watch(friendsRepositoryProvider).fetchSharedExpenses(friendId),
  retry: (int retryCount, Object error) => null,
);
