import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/widgets/expense_header.dart';
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

  ExpenseDetailModel detailModel() {
    return ExpenseDetailModel.fromJson(<String, dynamic>{
      'id': '550e8400-e29b-41d4-a716-446655440001',
      'group_id': '660e8400-e29b-41d4-a716-446655440002',
      'paid_by': <String, dynamic>{
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'display_name': 'Pat',
        'avatar_url': null,
      },
      'amount': '99.00',
      'currency': 'BRL',
      'exchange_rate_to_group_currency': '1.000000',
      'amount_in_group_currency': '99.00',
      'description': 'Dinner out',
      'category': 'comida',
      'expense_date': '2024-06-15',
      'split_method': 'equal',
      'splits': <dynamic>[],
      'receipt_urls': <dynamic>[],
      'created_by': <String, dynamic>{
        'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'display_name': 'Creator',
        'avatar_url': null,
      },
      'is_deleted': false,
      'deleted_at': null,
      'created_at': '2024-06-15T10:00:00.000Z',
      'updated_at': '2024-06-15T10:00:00.000Z',
    });
  }

  testWidgets('contains one CurrencyFormatterWidget and description', (tester) async {
    await tester.pumpWidget(
      app(
        ExpenseHeader(model: detailModel()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CurrencyFormatterWidget), findsOneWidget);
    expect(find.text('Dinner out'), findsOneWidget);
  });
}
