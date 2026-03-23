import 'package:flutter/material.dart';

import 'package:frontend/core/l10n/category_l10n.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.slug});

  final String slug;

  static IconData _iconForSlug(String slug) {
    return switch (slug) {
      'geral' => Icons.category,
      'comida' => Icons.restaurant,
      'transporte' => Icons.directions_car,
      'moradia' => Icons.home,
      'lazer' => Icons.sports_esports,
      'viagem' => Icons.flight,
      'utilidades' => Icons.electrical_services,
      _ => Icons.category,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Chip(
      avatar: Icon(_iconForSlug(slug), size: 18),
      label: Text(categoryDisplayName(l10n, slug)),
    );
  }
}
