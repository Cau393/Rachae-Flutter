import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/widgets/expense_list_tile.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  final model = ExpenseActivity(
    id: 'e1',
    type: 'expense',
    groupId: null,
    amount: '60.00',
    currency: 'BRL',
    createdAt: DateTime.utc(2024, 1, 1),
    description: 'Jantar',
    paidById: 'a1',
    paidByName: 'Ana',
  );

  Future<void> pumpTile(
    WidgetTester tester, {
    required ExpenseActivity item,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ExpenseListTile(item: item, onTap: onTap),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ExpenseListTile', () {
    testWidgets('shows title Jantar', (tester) async {
      await pumpTile(tester, item: model, onTap: () {});
      expect(find.text('Jantar'), findsOneWidget);
    });

    testWidgets('subtitle contains paid-by name via activityPaidBy', (tester) async {
      await pumpTile(tester, item: model, onTap: () {});
      expect(find.textContaining('Ana'), findsOneWidget);
    });

    testWidgets('shows one CurrencyFormatterWidget with amount raw 60.00', (tester) async {
      await pumpTile(tester, item: model, onTap: () {});
      expect(find.byType(CurrencyFormatterWidget), findsOneWidget);
      final fmt = tester.widget<CurrencyFormatterWidget>(
        find.byType(CurrencyFormatterWidget),
      );
      expect(fmt.amount.raw, '60.00');
    });

    testWidgets('tap invokes onTap', (tester) async {
      var tapped = false;
      await pumpTile(
        tester,
        item: model,
        onTap: () => tapped = true,
      );
      await tester.tap(find.byType(ExpenseListTile), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('onTap null tap does not throw and tile still exposes contract', (tester) async {
      await pumpTile(tester, item: model, onTap: null);
      await tester.tap(find.byType(ExpenseListTile), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Jantar'), findsOneWidget);
    });
  });
}
