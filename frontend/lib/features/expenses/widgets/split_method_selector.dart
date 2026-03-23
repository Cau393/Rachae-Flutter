import 'package:flutter/material.dart';

import 'package:frontend/core/l10n/split_method_l10n.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Segmented control for expense split method (`equal`, `exact`, `percentage`, `shares`).
class SplitMethodSelector extends StatelessWidget {
  const SplitMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  final String selectedMethod;
  final ValueChanged<String> onChanged;

  static const _methods = ['equal', 'exact', 'percentage', 'shares'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.addExpenseSplitMethodLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            for (final m in _methods)
              ButtonSegment<String>(
                value: m,
                label: Text(
                  splitMethodDisplayName(l10n, m),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          selected: {selectedMethod},
          onSelectionChanged: (set) {
            if (set.isEmpty) return;
            onChanged(set.first);
          },
        ),
      ],
    );
  }
}
