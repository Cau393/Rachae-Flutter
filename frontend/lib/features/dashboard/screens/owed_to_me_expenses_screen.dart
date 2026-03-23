import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/features/dashboard/providers/dashboard_shortcuts_providers.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class OwedToMeExpensesScreen extends ConsumerWidget {
  const OwedToMeExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(owedToMeExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardOwedToYouTitle),
      ),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.dashboardOwedToYouEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, i) => _expenseTile(context, l10n, list[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
      ),
    );
  }

  Widget _expenseTile(
    BuildContext context,
    AppLocalizations l10n,
    ExpenseListModel m,
  ) {
    return ListTile(
      leading: const Icon(Icons.receipt_long),
      title: Text(m.description),
      subtitle: Text(l10n.activityPaidBy(m.paidBy.displayName)),
      trailing: CurrencyFormatterWidget(amount: m.amountAsMoneyAmount),
      onTap: () => context.push('/expenses/${m.id}'),
    );
  }
}
