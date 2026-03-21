import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';
import 'package:frontend/core/l10n/category_l10n.dart';

Future<AppLocalizations> _loadPtBrL10n(WidgetTester tester) async {
  late AppLocalizations result;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (ctx) {
          result = AppLocalizations.of(ctx)!;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('geral maps to categoryGeral', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      categoryDisplayName(l10n, 'geral'),
      equals(l10n.categoryGeral),
    );
  });

  testWidgets('comida maps to categoryComida', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      categoryDisplayName(l10n, 'comida'),
      equals(l10n.categoryComida),
    );
  });

  testWidgets('transporte maps to categoryTransporte', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      categoryDisplayName(l10n, 'transporte'),
      equals(l10n.categoryTransporte),
    );
  });

  testWidgets('moradia maps to categoryMoradia', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      categoryDisplayName(l10n, 'moradia'),
      equals(l10n.categoryMoradia),
    );
  });

  testWidgets('lazer maps to categoryLazer', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      categoryDisplayName(l10n, 'lazer'),
      equals(l10n.categoryLazer),
    );
  });

  testWidgets('viagem maps to categoryViagem', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      categoryDisplayName(l10n, 'viagem'),
      equals(l10n.categoryViagem),
    );
  });

  testWidgets('utilidades maps to categoryUtilidades', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      categoryDisplayName(l10n, 'utilidades'),
      equals(l10n.categoryUtilidades),
    );
  });

  testWidgets('unknown slug outros returns raw slug', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(categoryDisplayName(l10n, 'outros'), equals('outros'));
  });
}
