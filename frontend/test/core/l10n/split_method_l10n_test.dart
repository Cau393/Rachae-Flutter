import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';
import 'package:frontend/core/l10n/split_method_l10n.dart';

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
  testWidgets('equal maps to addExpenseSplitMethodEqual', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      splitMethodDisplayName(l10n, 'equal'),
      equals(l10n.addExpenseSplitMethodEqual),
    );
  });

  testWidgets('exact maps to addExpenseSplitMethodExact', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      splitMethodDisplayName(l10n, 'exact'),
      equals(l10n.addExpenseSplitMethodExact),
    );
  });

  testWidgets('percentage maps to addExpenseSplitMethodPercentage',
      (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      splitMethodDisplayName(l10n, 'percentage'),
      equals(l10n.addExpenseSplitMethodPercentage),
    );
  });

  testWidgets('shares maps to addExpenseSplitMethodShares', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      splitMethodDisplayName(l10n, 'shares'),
      equals(l10n.addExpenseSplitMethodShares),
    );
  });

  testWidgets('unknown method custom returns raw method', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(splitMethodDisplayName(l10n, 'custom'), equals('custom'));
  });
}
