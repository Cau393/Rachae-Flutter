import 'package:flutter/material.dart';

import 'package:frontend/core/l10n/group_type_l10n.dart';
import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/widgets/group_net_balance_chip.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.model,
    required this.onTap,
  });

  final GroupSummaryModel model;
  final VoidCallback onTap;

  static IconData _iconForType(String type) {
    return switch (type) {
      'home' => Icons.home,
      'trip' => Icons.flight,
      'couple' => Icons.favorite,
      'other' => Icons.group,
      _ => Icons.group,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final subtitle =
        '${l10n.groupMemberCount(model.memberCount)} · ${model.currency}';

    final trailing = GroupNetBalanceChip(
      rawNetBalance: model.yourNetBalance,
      currency: model.currency,
      l10n: l10n,
    );

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Tooltip(
          message: groupTypeDisplayName(l10n, model.type),
          child: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(_iconForType(model.type)),
          ),
        ),
        title: Text(
          model.name,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}
