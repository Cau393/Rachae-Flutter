import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/widgets/settlement_list_tile.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  final unconfirmedItem = TransactionActivity(
    id: 't-unconfirmed',
    type: 'transaction',
    groupId: null,
    groupName: null,
    amount: '30.00',
    currency: 'BRL',
    createdAt: DateTime.utc(2024, 1, 1),
    payerId: 'bob',
    payerName: 'Bob',
    receiverId: 'ana',
    receiverName: 'Ana',
    note: null,
    isConfirmed: false,
  );

  final confirmedItem = TransactionActivity(
    id: 't-confirmed',
    type: 'transaction',
    groupId: null,
    groupName: null,
    amount: '30.00',
    currency: 'BRL',
    createdAt: DateTime.utc(2024, 1, 1),
    payerId: 'bob',
    payerName: 'Bob',
    receiverId: 'ana',
    receiverName: 'Ana',
    note: null,
    isConfirmed: true,
  );

  Future<void> pumpTile(WidgetTester tester, TransactionActivity item) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SettlementListTile(item: item),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10n(WidgetTester tester) {
    final ctx = tester.element(find.byType(SettlementListTile));
    return AppLocalizations.of(ctx)!;
  }

  group('SettlementListTile', () {
    testWidgets('unconfirmed: awaiting + recorded labels and one CurrencyFormatterWidget',
        (tester) async {
      await pumpTile(tester, unconfirmedItem);
      final strings = l10n(tester);
      expect(
        find.textContaining(strings.activityAwaitingConfirmation),
        findsOneWidget,
      );
      expect(find.text(strings.activitySettlementRecorded), findsOneWidget);
      expect(find.byType(CurrencyFormatterWidget), findsOneWidget);
    });

    testWidgets('confirmed: no awaiting label, confirmed label, one CurrencyFormatterWidget',
        (tester) async {
      await pumpTile(tester, confirmedItem);
      final strings = l10n(tester);
      expect(find.text(strings.activityAwaitingConfirmation), findsNothing);
      expect(find.text(strings.activitySettlementConfirmed), findsOneWidget);
      expect(find.byType(CurrencyFormatterWidget), findsOneWidget);
    });
  });
}
