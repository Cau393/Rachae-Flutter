import 'package:flutter/material.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class BalanceSummaryCard extends StatelessWidget {
  const BalanceSummaryCard({super.key, required this.model});

  final BalanceSummaryModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AmountRow(
              label: l10n.dashboardYouOwe,
              amount: model.totalOwedAsAmount,
              colorCoded: false,
            ),
            const SizedBox(height: 12),
            _AmountRow(
              label: l10n.dashboardYouAreOwed,
              amount: model.totalOwingAsAmount,
              colorCoded: false,
            ),
            const SizedBox(height: 12),
            _AmountRow(
              label: l10n.dashboardNetBalance,
              amount: model.netBalanceAsAmount,
              colorCoded: true,
              showSign: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    required this.colorCoded,
    this.showSign = false,
  });

  final String label;
  final MoneyAmount amount;
  final bool colorCoded;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        CurrencyFormatterWidget(
          amount: amount,
          colorCoded: colorCoded,
          showSign: showSign,
        ),
      ],
    );
  }
}
