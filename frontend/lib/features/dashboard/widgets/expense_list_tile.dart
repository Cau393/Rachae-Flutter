import 'package:flutter/material.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    super.key,
    required this.item,
    this.onTap,
  });

  final ExpenseActivity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.receipt_long),
      title: Text(item.description),
      subtitle: Text(l10n.activityPaidBy(item.paidByName)),
      trailing: CurrencyFormatterWidget(amount: item.amountAsMoneyAmount),
      onTap: onTap,
    );
  }
}
