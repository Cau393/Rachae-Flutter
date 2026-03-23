import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/widgets/expense_list_tile.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';
import 'package:frontend/features/expenses/providers/group_expense_list_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class GroupExpenseList extends ConsumerStatefulWidget {
  const GroupExpenseList({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupExpenseList> createState() => _GroupExpenseListState();
}

class _GroupExpenseListState extends ConsumerState<GroupExpenseList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels >= pos.maxScrollExtent * 0.85) {
      ref.read(groupExpenseListProvider(widget.groupId).notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(groupExpenseListProvider(widget.groupId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(groupExpenseListProvider(widget.groupId));

    if (async.isLoading && !async.hasValue) {
      return KeyedSubtree(
        key: ValueKey<String>(widget.groupId),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (async.hasError && !async.hasValue) {
      return KeyedSubtree(
        key: ValueKey<String>(widget.groupId),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.errorGeneric),
              TextButton(
                onPressed: () => ref.invalidate(
                  groupExpenseListProvider(widget.groupId),
                ),
                child: Text(l10n.retryLabel),
              ),
            ],
          ),
        ),
      );
    }

    if (!async.hasValue) {
      return KeyedSubtree(
        key: ValueKey<String>(widget.groupId),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return KeyedSubtree(
      key: ValueKey<String>(widget.groupId),
      child: _buildData(context, l10n, async.requireValue),
    );
  }

  Widget _buildData(
    BuildContext context,
    AppLocalizations l10n,
    List<ExpenseListModel> expenses,
  ) {
    if (expenses.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(l10n.groupDetailNoExpenses)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final e = expenses[index];
          return ExpenseListTile(
            item: ExpenseActivity.fromExpenseListModel(e),
            onTap: () => context.go('/expenses/${e.id}'),
          );
        },
      ),
    );
  }
}
