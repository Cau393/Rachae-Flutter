import 'package:flutter/material.dart';

import 'package:frontend/src/l10n/generated/app_localizations.dart';

class SimplifyDebtsToggle extends StatelessWidget {
  const SimplifyDebtsToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      title: Text(l10n.createGroupSimplifyDebts),
      value: value,
      onChanged: onChanged,
    );
  }
}
