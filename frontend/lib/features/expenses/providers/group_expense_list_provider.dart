import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/expenses/models/expense_list_model.dart';
import 'package:frontend/features/expenses/providers/expense_repository_provider.dart';

final groupExpenseListProvider = AsyncNotifierProvider.autoDispose
    .family<GroupExpenseListNotifier, List<ExpenseListModel>, String>(
  GroupExpenseListNotifier.new,
);

List<ExpenseListModel> mergeExpenseListDedupe(
  List<ExpenseListModel> base,
  List<ExpenseListModel> incoming,
) {
  final ids = base.map((e) => e.id).toSet();
  final out = [...base];
  for (final item in incoming) {
    if (ids.add(item.id)) {
      out.add(item);
    }
  }
  return out;
}

class GroupExpenseListNotifier extends AsyncNotifier<List<ExpenseListModel>> {
  GroupExpenseListNotifier(this.groupId);

  final String groupId;

  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  Future<List<ExpenseListModel>> build() async {
    _currentPage = 1;
    _hasMore = true;
    _loadingMore = false;
    final repo = ref.watch(expenseRepositoryProvider);
    final list = await repo.fetchGroupExpenses(groupId, page: 1, limit: 20);
    if (list.isEmpty) {
      _hasMore = false;
    }
    return list;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    final current = state.value;
    if (current == null) return;

    _loadingMore = true;
    try {
      final repo = ref.read(expenseRepositoryProvider);
      _currentPage++;
      final more = await repo.fetchGroupExpenses(
        groupId,
        page: _currentPage,
        limit: 20,
      );
      if (more.isEmpty) {
        _hasMore = false;
        return;
      }
      state = AsyncData(mergeExpenseListDedupe(current, more));
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    _loadingMore = false;
    _currentPage = 1;
    _hasMore = true;
    final repo = ref.read(expenseRepositoryProvider);
    final list = await repo.fetchGroupExpenses(groupId, page: 1, limit: 20);
    if (list.isEmpty) {
      _hasMore = false;
    }
    state = AsyncData(list);
  }
}
