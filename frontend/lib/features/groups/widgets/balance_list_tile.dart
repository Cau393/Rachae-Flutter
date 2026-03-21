import 'package:flutter/material.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/features/groups/models/group_balance_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class BalanceListTile extends StatelessWidget {
  const BalanceListTile({
    super.key,
    required this.balance,
    required this.currency,
    required this.isCurrentUser,
  });

  final GroupBalanceModel balance;
  final String currency;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = isCurrentUser
        ? '${balance.displayName} ${l10n.groupMemberCurrentUserSuffix}'
        : balance.displayName;

    return ListTile(
      title: Text(title),
      trailing: CurrencyFormatterWidget(
        amount: balance.netBalanceAsAmount(currency),
        colorCoded: true,
        showSign: true,
      ),
    );
  }
}
