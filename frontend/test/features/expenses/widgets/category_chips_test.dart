import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/l10n/category_l10n.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/expenses/widgets/category_chips.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  Widget app(Widget home) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    );
  }

  const slugs = <String>[
    'geral',
    'comida',
    'transporte',
    'moradia',
    'lazer',
    'viagem',
    'utilidades',
  ];

  group('CategoryChips', () {
    testWidgets('renders seven ChoiceChip widgets', (tester) async {
      await tester.pumpWidget(
        app(
          CategoryChips(
            selectedCategory: 'geral',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNWidgets(7));
    });

    testWidgets('chip selected state matches selectedCategory', (tester) async {
      await tester.pumpWidget(
        app(
          CategoryChips(
            selectedCategory: 'comida',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final slug in slugs) {
        final chip = tester.widget<ChoiceChip>(
          find.byKey(ValueKey<String>('category-chip-$slug')),
        );
        expect(chip.selected, slug == 'comida');
      }
    });

    testWidgets('tapping unselected chip calls onChanged with slug', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        app(
          CategoryChips(
            selectedCategory: 'geral',
            onChanged: values.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey<String>('category-chip-lazer')));
      await tester.pumpAndSettle();

      expect(values, ['lazer']);
    });

    testWidgets('each chip label matches categoryDisplayName for slug',
        (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return CategoryChips(
                selectedCategory: 'geral',
                onChanged: (_) {},
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final slug in slugs) {
        expect(
          find.text(categoryDisplayName(l10n, slug)),
          findsOneWidget,
        );
      }
    });
  });
}
