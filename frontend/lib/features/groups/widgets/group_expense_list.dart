import 'package:flutter/material.dart';

import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Placeholder until Phase 20 — lists group expenses.
class GroupExpenseList extends StatelessWidget {
  const GroupExpenseList({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      key: ValueKey<String>(groupId),
      child: Text(l10n.groupDetailNoExpenses),
    );
  }
}
