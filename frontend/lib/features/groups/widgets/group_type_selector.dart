import 'package:flutter/material.dart';

import 'package:frontend/core/l10n/group_type_l10n.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class GroupTypeSelector extends StatelessWidget {
  const GroupTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const List<String> slugs = <String>['home', 'trip', 'couple', 'other'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      isExpanded: true,
      // ignore: deprecated_member_use — parent-driven selection.
      value: slugs.contains(value) ? value : slugs.first,
      decoration: InputDecoration(labelText: l10n.createGroupTypeLabel),
      items: slugs
          .map(
            (slug) => DropdownMenuItem<String>(
              value: slug,
              child: Text(
                groupTypeDisplayName(l10n, slug),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
