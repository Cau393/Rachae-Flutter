import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/currency/currency_formatter.dart';
import 'package:frontend/features/groups/models/settlement_suggestion_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class SettlementSuggestionTile extends StatelessWidget {
  const SettlementSuggestionTile({
    super.key,
    required this.groupId,
    required this.suggestion,
  });

  final String groupId;
  final SettlementSuggestionModel suggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountLabel =
        CurrencyFormatter.format(suggestion.amountAsMoneyAmount);
    return ListTile(
      leading: const Icon(Icons.arrow_forward),
      title: Text(
        l10n.groupDetailOwes(
          suggestion.payerName,
          amountLabel,
          suggestion.receiverName,
        ),
      ),
      trailing: TextButton(
        onPressed: () {
          final uri = Uri(
            path: '/settle',
            queryParameters: <String, String>{
              'group_id': groupId,
              'receiver_id': suggestion.receiverId,
              'amount': suggestion.amount,
            },
          );
          context.go(uri.toString());
        },
        child: Text(l10n.groupDetailSettleUp),
      ),
    );
  }
}
