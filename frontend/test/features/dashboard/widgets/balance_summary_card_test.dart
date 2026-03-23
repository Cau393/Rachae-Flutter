import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/widgets/balance_summary_card.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  group('BalanceSummaryCard', () {
    final negativeNetModel = BalanceSummaryModel.fromJson({
      'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'total_owed': '45.00',
      'total_owing': '120.50',
      'net_balance': '-75.50',
      'currency': 'BRL',
    });

    Future<void> pumpCard(WidgetTester tester, BalanceSummaryModel model) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BalanceSummaryCard(model: model),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    AppLocalizations l10n(WidgetTester tester) {
      final ctx = tester.element(find.byType(BalanceSummaryCard));
      return AppLocalizations.of(ctx)!;
    }

    testWidgets('renders three CurrencyFormatterWidget instances', (tester) async {
      await pumpCard(tester, negativeNetModel);
      expect(find.byType(CurrencyFormatterWidget), findsNWidgets(3));
    });

    testWidgets('shows dashboardYouOwe, dashboardYouAreOwed, dashboardNetBalance labels',
        (tester) async {
      await pumpCard(tester, negativeNetModel);
      final strings = l10n(tester);
      expect(find.text(strings.dashboardYouOwe), findsOneWidget);
      expect(find.text(strings.dashboardYouAreOwed), findsOneWidget);
      expect(find.text(strings.dashboardNetBalance), findsOneWidget);
    });

    testWidgets('net balance CurrencyFormatterWidget has colorCoded true when net is negative',
        (tester) async {
      await pumpCard(tester, negativeNetModel);
      final netFinder = find.byWidgetPredicate(
        (w) =>
            w is CurrencyFormatterWidget &&
            w.amount.raw == negativeNetModel.netBalance,
      );
      expect(netFinder, findsOneWidget);
      final netWidget = tester.widget<CurrencyFormatterWidget>(netFinder);
      expect(netWidget.colorCoded, isTrue);
    });

    testWidgets('positive net_balance still renders structural contract', (tester) async {
      final positiveNet = BalanceSummaryModel.fromJson({
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'total_owed': '100.00',
        'total_owing': '20.00',
        'net_balance': '50.00',
        'currency': 'BRL',
      });
      await pumpCard(tester, positiveNet);
      expect(find.byType(CurrencyFormatterWidget), findsNWidgets(3));
      final strings = l10n(tester);
      expect(find.text(strings.dashboardYouOwe), findsOneWidget);
    });

    testWidgets('zero net balance uses colorCoded net row for neutral styling', (tester) async {
      final zeroNet = BalanceSummaryModel.fromJson({
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'total_owed': '0.00',
        'total_owing': '0.00',
        'net_balance': '0.00',
        'currency': 'BRL',
      });
      await pumpCard(tester, zeroNet);
      final netFinder = find.byWidgetPredicate(
        (w) =>
            w is CurrencyFormatterWidget &&
            w.colorCoded &&
            w.amount.raw == zeroNet.netBalance &&
            w.amount.isZero,
      );
      expect(netFinder, findsOneWidget);
      final netWidget = tester.widget<CurrencyFormatterWidget>(netFinder);
      expect(netWidget.colorCoded, isTrue);
    });
  });
}
