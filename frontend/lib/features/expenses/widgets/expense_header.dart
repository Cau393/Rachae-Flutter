import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/widgets/category_badge.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class ExpenseHeader extends StatelessWidget {
  const ExpenseHeader({super.key, required this.model});

  final ExpenseDetailModel model;

  static String _paidByInitial(String displayName) {
    final t = displayName.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateText = DateFormat('dd/MM/yyyy').format(model.expenseDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CurrencyFormatterWidget(
              amount: model.amountAsMoneyAmount,
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              model.description,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            CategoryBadge(slug: model.category),
            const SizedBox(height: 8),
            Text(dateText),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  child: Text(_paidByInitial(model.paidBy.displayName)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.expenseDetailPaidBy(model.paidBy.displayName),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
