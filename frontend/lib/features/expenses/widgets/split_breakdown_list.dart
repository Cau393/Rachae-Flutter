import 'package:flutter/material.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/features/expenses/models/split_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Positive-balance green aligned with [CurrencyFormatterWidget] colorCoded.
const Color _settledIconColor = Color(0xFF2E7D32);

class SplitBreakdownList extends StatelessWidget {
  const SplitBreakdownList({
    super.key,
    required this.splits,
    required this.currency,
  });

  final List<SplitModel> splits;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.displayName),
              trailing: s.isSettled
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: _settledIconColor,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(l10n.expenseDetailSettled),
                      ],
                    )
                  : CurrencyFormatterWidget(
                      amount: s.amountOwedAsMoneyAmount(currency),
                    ),
            );
          },
        ),
      ],
    );
  }
}
