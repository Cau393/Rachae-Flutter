import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/friends/widgets/pending_transaction_tile.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  const payerId = '11111111-1111-1111-1111-111111111111';
  const receiverId = '22222222-2222-2222-2222-222222222222';

  TransactionModel txn({
    bool isConfirmed = false,
    bool isDisputed = false,
    String payerName = 'Pat',
    String receiverName = 'Rex',
    String? groupId,
    String? groupName,
  }) =>
      TransactionModel.fromJson(<String, dynamic>{
        'id': 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
        'group_id': groupId,
        'group_name': groupName,
        'payer': <String, dynamic>{
          'user_id': payerId,
          'display_name': payerName,
          'avatar_url': null,
        },
        'receiver': <String, dynamic>{
          'user_id': receiverId,
          'display_name': receiverName,
          'avatar_url': null,
        },
        'amount': '50.00',
        'currency': 'BRL',
        'note': null,
        'is_confirmed': isConfirmed,
        'is_disputed': isDisputed,
        'created_at': '2026-03-20T15:30:00Z',
      });

  Future<void> pumpTile(
    WidgetTester tester, {
    required TransactionModel transaction,
    required String currentUserId,
    VoidCallback? onConfirm,
    VoidCallback? onDispute,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PendingTransactionTile(
            transaction: transaction,
            currentUserId: currentUserId,
            onConfirm: onConfirm ?? () {},
            onDispute: onDispute ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'when currentUserId is payer: payer perspective title; no confirm/dispute',
    (tester) async {
      await pumpTile(
        tester,
        transaction: txn(payerName: 'Self', receiverName: 'Rex'),
        currentUserId: payerId,
      );

      expect(find.byIcon(Icons.payments), findsOneWidget);
      expect(find.textContaining('You paid '), findsOneWidget);
      expect(find.textContaining(' to Rex'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(find.byIcon(Icons.cancel_outlined), findsNothing);
    },
  );

  testWidgets(
    'when currentUserId is receiver and pending: confirm and dispute IconButtons',
    (tester) async {
      await pumpTile(
        tester,
        transaction: txn(),
        currentUserId: receiverId,
      );

      expect(find.textContaining('Pat sent you '), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    },
  );

  testWidgets('when isConfirmed: confirmed chip; no action buttons', (tester) async {
    await pumpTile(
      tester,
      transaction: txn(isConfirmed: true),
      currentUserId: receiverId,
    );

    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
  });

  testWidgets('when isDisputed: disputed chip; no action buttons', (tester) async {
    await pumpTile(
      tester,
      transaction: txn(isDisputed: true),
      currentUserId: receiverId,
    );

    expect(find.text('Disputed'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
  });

  testWidgets('tapping confirm calls onConfirm', (tester) async {
    var calls = 0;
    await pumpTile(
      tester,
      transaction: txn(),
      currentUserId: receiverId,
      onConfirm: () => calls++,
    );

    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('tapping dispute calls onDispute', (tester) async {
    var calls = 0;
    await pumpTile(
      tester,
      transaction: txn(),
      currentUserId: receiverId,
      onDispute: () => calls++,
    );

    await tester.tap(find.byIcon(Icons.cancel_outlined));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('CurrencyFormatterWidget is present for amount', (tester) async {
    await pumpTile(
      tester,
      transaction: txn(),
      currentUserId: payerId,
    );

    expect(find.byType(CurrencyFormatterWidget), findsOneWidget);
    final fmt = tester.widget<CurrencyFormatterWidget>(
      find.byType(CurrencyFormatterWidget),
    );
    expect(fmt.amount.raw, '50.00');
    expect(fmt.amount.currencyCode, 'BRL');
  });

  testWidgets('shows group name when present', (tester) async {
    await pumpTile(
      tester,
      transaction: txn(groupId: 'g-1', groupName: 'Trip Group'),
      currentUserId: receiverId,
    );

    expect(find.text('Trip Group'), findsOneWidget);
  });

  testWidgets('shows Personal label when group is null', (tester) async {
    await pumpTile(
      tester,
      transaction: txn(groupId: null, groupName: null),
      currentUserId: receiverId,
    );

    expect(find.text('Personal'), findsOneWidget);
  });
}
