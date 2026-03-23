import 'package:flutter/material.dart';

import 'package:frontend/features/expenses/models/expense_form_state.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class PaidByDropdown extends StatelessWidget {
  const PaidByDropdown({
    super.key,
    required this.participants,
    required this.valueUserId,
    required this.onChanged,
  });

  final List<SplitParticipant> participants;
  final String valueUserId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effective = participants.any((p) => p.userId == valueUserId)
        ? valueUserId
        : (participants.isNotEmpty ? participants.first.userId : null);

    return DropdownButtonFormField<String>(
      isExpanded: true,
      // ignore: deprecated_member_use — parent-driven selection.
      value: effective,
      decoration: InputDecoration(labelText: l10n.addExpensePaidByLabel),
      items: participants
          .map(
            (p) => DropdownMenuItem<String>(
              value: p.userId,
              child: Text(p.displayName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: effective == null
          ? null
          : (v) {
              if (v != null) onChanged(v);
            },
    );
  }
}
