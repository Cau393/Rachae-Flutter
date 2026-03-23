import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/currency/currency_formatter.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/expenses/widgets/amount_field.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void _noop(String _) {}

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

  group('AmountField', () {
    testWidgets('entering 150,50 calls onChanged with 150.50', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        app(
          AmountField(
            value: '',
            currency: 'BRL',
            onChanged: values.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '150,50');
      await tester.pumpAndSettle();

      expect(values, isNotEmpty);
      expect(values.last, '150.50');
    });

    testWidgets('letters are rejected; onChanged not called', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        app(
          AmountField(
            value: '',
            currency: 'BRL',
            onChanged: values.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      expect(values, isEmpty);
    });

    testWidgets('shows converted preview when non-null', (tester) async {
      await tester.pumpWidget(
        app(
          const AmountField(
            value: '',
            currency: 'USD',
            onChanged: _noop,
            convertedPreview: '50.00',
            convertedPreviewCurrency: 'BRL',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('50,00'), findsOneWidget);
    });

    testWidgets('hides preview when convertedPreview is null', (tester) async {
      late String previewWhenUsed;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              previewWhenUsed = AppLocalizations.of(context)!
                  .addExpenseConvertedPreview('50.00', 'BRL');
              return AmountField(
                value: '',
                currency: 'BRL',
                onChanged: (_) {},
                convertedPreview: null,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(previewWhenUsed), findsNothing);
    });

    testWidgets('displays BRL currency symbol prefix', (tester) async {
      await tester.pumpWidget(
        app(
          AmountField(
            value: '',
            currency: 'BRL',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(CurrencyFormatter.symbolFor('BRL')), findsOneWidget);
    });

    testWidgets('TextField uses numberWithOptions(decimal: true)', (tester) async {
      await tester.pumpWidget(
        app(
          AmountField(
            value: '',
            currency: 'BRL',
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType.decimal, isTrue);
      expect(
        field.keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );
    });
  });
}
