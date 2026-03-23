import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/currencies/providers/currency_providers.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class CurrencyDropdown extends ConsumerWidget {
  const CurrencyDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.currencyLabel,
  });

  final String value;
  final ValueChanged<String> onChanged;

  /// When null, uses [AppLocalizations.createGroupCurrencyLabel].
  final String? currencyLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final label = currencyLabel ?? l10n.createGroupCurrencyLabel;
    final async = ref.watch(currencyListProvider);

    return async.when(
      data: (currencies) {
        final codes = currencies.map((c) => c.code).toList();
        final effective = codes.contains(value) ? value : (codes.isNotEmpty ? codes.first : value);
        return DropdownButtonFormField<String>(
          isExpanded: true,
          // ignore: deprecated_member_use — parent-driven selection; initialValue is one-shot only.
          value: effective,
          decoration: InputDecoration(labelText: label),
          items: currencies
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c.code,
                  child: Text(
                    c.code,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        );
      },
      loading: () => DropdownButtonFormField<String>(
        isExpanded: true,
        // ignore: deprecated_member_use
        value: value,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem<String>(
            value: value,
            child: Text(value, overflow: TextOverflow.ellipsis),
          ),
        ],
        onChanged: null,
      ),
      error: (_, _) => DropdownButtonFormField<String>(
        isExpanded: true,
        // ignore: deprecated_member_use
        value: value,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem<String>(
            value: value,
            child: Text(value, overflow: TextOverflow.ellipsis),
          ),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
