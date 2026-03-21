import 'package:flutter/material.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class SettlementListTile extends StatelessWidget {
  const SettlementListTile({super.key, required this.item});

  final TransactionActivity item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.payments),
      title: Text('${item.payerName} → ${item.receiverName}'),
      subtitle: item.isConfirmed
          ? Text(l10n.activitySettlementConfirmed)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.activitySettlementRecorded),
                const SizedBox(height: 6),
                Chip(
                  label: Text(l10n.activityAwaitingConfirmation),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
      isThreeLine: !item.isConfirmed,
      trailing: CurrencyFormatterWidget(amount: item.amountAsMoneyAmount),
    );
  }
}
