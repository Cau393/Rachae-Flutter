import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/expenses/models/split_model.dart';
import 'package:frontend/features/expenses/widgets/split_breakdown_list.dart';
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

  SplitModel makeSplit({
    required String id,
    required String name,
    required String amount,
    required bool settled,
  }) {
    return SplitModel(
      id: id,
      userId: 'u-$id',
      displayName: name,
      avatarUrl: null,
      amountOwed: amount,
      shareValue: null,
      isSettled: settled,
    );
  }

  testWidgets('two unsettled splits render two CurrencyFormatterWidgets',
      (tester) async {
    final splits = [
      makeSplit(id: '1', name: 'A', amount: '10.00', settled: false),
      makeSplit(id: '2', name: 'B', amount: '20.00', settled: false),
    ];

    await tester.pumpWidget(
      app(
        SingleChildScrollView(
          child: SplitBreakdownList(splits: splits, currency: 'BRL'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CurrencyFormatterWidget), findsNWidgets(2));
  });

  testWidgets('settled split shows settled label, not amount formatter',
      (tester) async {
    await tester.pumpWidget(
      app(
        SingleChildScrollView(
          child: SplitBreakdownList(
            splits: [
              makeSplit(id: '1', name: 'Open', amount: '5.00', settled: false),
              makeSplit(id: '2', name: 'Done', amount: '15.00', settled: true),
            ],
            currency: 'BRL',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l = AppLocalizations.of(
      tester.element(find.text('Open')),
    )!;

    expect(find.text(l.expenseDetailSettled), findsOneWidget);
    expect(find.byType(CurrencyFormatterWidget), findsOneWidget);

    final doneTile = find.ancestor(
      of: find.text('Done'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(
        of: doneTile,
        matching: find.byType(CurrencyFormatterWidget),
      ),
      findsNothing,
    );
  });
}
