import 'package:flutter/material.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Group list / detail chip: settled, creditor (green), or debtor (red).
class GroupNetBalanceChip extends StatelessWidget {
  const GroupNetBalanceChip({
    super.key,
    required this.rawNetBalance,
    required this.currency,
    required this.l10n,
  });

  final String rawNetBalance;
  final String currency;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (GroupSummaryModel.netBalanceRawIsZero(rawNetBalance)) {
      return Chip(
        backgroundColor: colorScheme.surfaceContainerHighest,
        label: Text(l10n.groupBalanceZero),
      );
    }
    final amount = MoneyAmount.fromApiString(rawNetBalance.trim(), currency);
    final chipBg = GroupSummaryModel.netBalanceRawIsPositive(rawNetBalance)
        ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
        : colorScheme.error.withValues(alpha: 0.15);
    return Chip(
      backgroundColor: chipBg,
      label: CurrencyFormatterWidget(
        amount: amount,
        colorCoded: true,
        showSign: true,
      ),
    );
  }
}
