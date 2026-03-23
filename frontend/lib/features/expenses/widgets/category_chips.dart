import 'package:flutter/material.dart';

import 'package:frontend/core/l10n/category_l10n.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Horizontal category picker for expense form. Order is fixed (strategy doc).
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onChanged;

  static const List<String> _slugs = [
    'geral',
    'comida',
    'transporte',
    'moradia',
    'lazer',
    'viagem',
    'utilidades',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _slugs.map((slug) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: ValueKey<String>('category-chip-$slug'),
              label: Text(categoryDisplayName(l10n, slug)),
              selected: slug == selectedCategory,
              onSelected: (selected) {
                if (selected) {
                  onChanged(slug);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
