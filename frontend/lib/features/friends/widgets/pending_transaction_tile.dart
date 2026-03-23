import 'package:flutter/material.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class PendingTransactionTile extends StatelessWidget {
  const PendingTransactionTile({
    super.key,
    required this.transaction,
    required this.currentUserId,
    required this.onConfirm,
    required this.onDispute,
  });

  final TransactionModel transaction;
  final String currentUserId;
  final VoidCallback onConfirm;
  final VoidCallback onDispute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium;

    final isCurrentUserPayer = transaction.payer.userId == currentUserId;
    final isCurrentUserReceiver = transaction.receiver.userId == currentUserId;

    final status = transaction.isConfirmed
        ? 'confirmed'
        : transaction.isDisputed
            ? 'disputed'
            : 'pending';

    final Widget title;
    if (isCurrentUserPayer) {
      title = Row(
        children: [
          Text(
            l10n.pendingSettlementYouPaidBeforeAmount,
            style: titleStyle,
          ),
          CurrencyFormatterWidget(
            amount: transaction.amountAsMoneyAmount,
            style: titleStyle,
          ),
          Flexible(
            child: Text(
              l10n.pendingSettlementYouPaidAfterAmount(
                transaction.receiver.displayName,
              ),
              style: titleStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      title = Row(
        children: [
          Flexible(
            child: Text(
              l10n.pendingSettlementReceivedBeforeAmount(
                transaction.payer.displayName,
              ),
              style: titleStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CurrencyFormatterWidget(
            amount: transaction.amountAsMoneyAmount,
            style: titleStyle,
          ),
        ],
      );
    }

    late final Color chipBg;
    late final Color chipFg;
    late final String chipLabel;
    switch (status) {
      case 'confirmed':
        chipBg = Colors.green.shade100;
        chipFg = theme.colorScheme.onSurface;
        chipLabel = l10n.settleUpConfirmed;
        break;
      case 'disputed':
        chipBg = theme.colorScheme.errorContainer;
        chipFg = theme.colorScheme.onErrorContainer;
        chipLabel = l10n.settleUpDisputed;
        break;
      default:
        chipBg = Colors.amber.shade100;
        chipFg = theme.colorScheme.onSurface;
        chipLabel = l10n.settleUpAwaitingConfirmation;
    }

    final Widget? trailing = isCurrentUserReceiver && status == 'pending'
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF2E7D32),
                ),
                onPressed: onConfirm,
              ),
              IconButton(
                icon: Icon(
                  Icons.cancel_outlined,
                  color: theme.colorScheme.error,
                ),
                onPressed: onDispute,
              ),
            ],
          )
        : null;

    return ListTile(
      leading: const Icon(Icons.payments),
      title: title,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Chip(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          label: Text(chipLabel, style: TextStyle(color: chipFg)),
          backgroundColor: chipBg,
          side: BorderSide.none,
        ),
      ),
      trailing: trailing,
    );
  }
}
