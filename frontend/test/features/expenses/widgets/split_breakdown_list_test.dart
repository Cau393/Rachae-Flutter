import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/widgets/split_breakdown_list.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

ExpenseDetailModel _makeDetail({
  required String amount,
  required String splitMethod,
  required List<Map<String, dynamic>> splitsMaps,
  String? paidById,
  String? payerName,
}) {
  final payerId = paidById ?? splitsMaps.first['user_id'].toString();
  final pName = payerName ?? 'Payer';
  return ExpenseDetailModel.fromJson({
    'id': '550e8400-e29b-41d4-a716-446655440001',
    'group_id': null,
    'paid_by': {
      'id': payerId,
      'display_name': pName,
      'avatar_url': null,
    },
    'amount': amount,
    'currency': 'BRL',
    'amount_in_group_currency': amount,
    'description': 'Test',
    'category': 'geral',
    'expense_date': '2024-02-01',
    'split_method': splitMethod,
    'is_deleted': false,
    'created_at': '2024-02-01T10:00:00.000Z',
    'updated_at': '2024-02-02T11:30:00.000Z',
    'deleted_at': null,
    'splits': splitsMaps,
    'receipt_urls': <dynamic>[],
    'created_by': {
      'id': payerId,
      'display_name': pName,
      'avatar_url': null,
    },
    'exchange_rate_to_group_currency': '1.000000',
  });
}

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

  testWidgets('payer row shows nominal share not inflated amount_owed',
      (tester) async {
    const payerId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    const otherId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    final detail = _makeDetail(
      amount: '30.00',
      splitMethod: 'equal',
      paidById: payerId,
      splitsMaps: [
        {
          'id': '1',
          'user_id': payerId,
          'display_name': 'Payer',
          'avatar_url': null,
          'amount_owed': '30.00',
          'share_value': null,
          'is_settled': false,
        },
        {
          'id': '2',
          'user_id': otherId,
          'display_name': 'Other',
          'avatar_url': null,
          'amount_owed': '0.00',
          'share_value': null,
          'is_settled': true,
        },
      ],
    );

    await tester.pumpWidget(
      app(
        SingleChildScrollView(
          child: SplitBreakdownList(detail: detail),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CurrencyFormatterWidget), findsNWidgets(2));
    final l10n = AppLocalizations.of(
      tester.element(find.text('Payer')),
    )!;
    expect(find.text(l10n.expenseDetailSettled), findsOneWidget);
  });

  testWidgets('two unsettled equal splits show two amounts', (tester) async {
    const id1 = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    const id2 = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    final detail = _makeDetail(
      amount: '10.00',
      splitMethod: 'equal',
      paidById: id1,
      splitsMaps: [
        {
          'id': '1',
          'user_id': id1,
          'display_name': 'A',
          'avatar_url': null,
          'amount_owed': '10.00',
          'share_value': null,
          'is_settled': false,
        },
        {
          'id': '2',
          'user_id': id2,
          'display_name': 'B',
          'avatar_url': null,
          'amount_owed': '10.00',
          'share_value': null,
          'is_settled': false,
        },
      ],
    );

    await tester.pumpWidget(
      app(
        SingleChildScrollView(
          child: SplitBreakdownList(detail: detail),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CurrencyFormatterWidget), findsNWidgets(2));
    expect(find.textContaining('5'), findsWidgets);
  });
}
