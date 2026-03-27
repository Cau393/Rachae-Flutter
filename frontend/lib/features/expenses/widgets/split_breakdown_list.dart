import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/models/split_model.dart';
import 'package:frontend/features/expenses/utils/nominal_split_amounts.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Positive-balance green aligned with [CurrencyFormatterWidget] colorCoded.
const Color _settledIconColor = Color(0xFF2E7D32);

class SplitBreakdownList extends StatelessWidget {
  const SplitBreakdownList({
    super.key,
    required this.detail,
  });

  final ExpenseDetailModel detail;

  static String _displayAmountRaw({
    required SplitModel split,
    required int index,
    required ExpenseDetailModel detail,
    required List<Decimal>? nominals,
  }) {
    if (nominals == null || nominals.length != detail.splits.length) {
      return split.amountOwed.trim();
    }
    final nominal = nominals[index];
    final nominalStr = nominal.toStringAsFixed(2);
    if (split.isSettled) {
      return nominalStr;
    }
    if (split.userId == detail.paidBy.userId) {
      return nominalStr;
    }
    return split.amountOwed.trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final splits = detail.splits;
    final currency = detail.currency;
    final nominals = tryComputeNominalShares(
      splitMethod: detail.splitMethod,
      expenseTotalAmount: detail.amount,
      splits: splits,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.expenseDetailSplitBreakdown,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: splits.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final s = splits[i];
            final raw = _displayAmountRaw(
              split: s,
              index: i,
              detail: detail,
              nominals: nominals,
            );
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.displayName),
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurrencyFormatterWidget(
                      amount: MoneyAmount.fromApiString(raw, currency),
                    ),
                    if (s.isSettled) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: _settledIconColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.expenseDetailSettled,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
