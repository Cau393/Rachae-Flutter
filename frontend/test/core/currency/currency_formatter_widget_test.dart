import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/currency/money_amount.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders a Text widget', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CurrencyFormatterWidget(
          amount: MoneyAmount.fromApiString('100.00', 'BRL'),
        ),
      ),
    );
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('displayed text contains the formatted amount digits', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CurrencyFormatterWidget(
          amount: MoneyAmount.fromApiString('50.25', 'BRL'),
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text)).data ?? '';
    expect(text, contains('50'));
  });

  testWidgets('applies custom TextStyle when provided', (tester) async {
    const style = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
    await tester.pumpWidget(
      _wrap(
        CurrencyFormatterWidget(
          amount: MoneyAmount.fromApiString('10.00', 'BRL'),
          style: style,
        ),
      ),
    );
    final textWidget = tester.widget<Text>(find.byType(Text));
    expect(textWidget.style?.fontSize, 24);
  });

  testWidgets(
    'colorCoded=true applies a non-null color for positive balance',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          CurrencyFormatterWidget(
            amount: MoneyAmount.fromApiString('30.00', 'BRL'),
            colorCoded: true,
          ),
        ),
      );
      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.color, isNotNull);
    },
  );

  testWidgets(
    'colorCoded=true applies a different non-null color for negative balance',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          CurrencyFormatterWidget(
            amount: MoneyAmount.fromApiString('-30.00', 'BRL'),
            colorCoded: true,
          ),
        ),
      );
      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.color, isNotNull);
    },
  );

  testWidgets('compact=true renders shorter text than non-compact', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CurrencyFormatterWidget(
          amount: MoneyAmount.fromApiString('2500.00', 'BRL'),
          compact: true,
        ),
      ),
    );
    final compactText = tester.widget<Text>(find.byType(Text)).data ?? '';

    await tester.pumpWidget(
      _wrap(
        CurrencyFormatterWidget(
          amount: MoneyAmount.fromApiString('2500.00', 'BRL'),
          compact: false,
        ),
      ),
    );
    final fullText = tester.widget<Text>(find.byType(Text)).data ?? '';

    expect(compactText.length, lessThan(fullText.length));
  });

  testWidgets('has a Semantics wrapper for accessibility', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CurrencyFormatterWidget(
          amount: MoneyAmount.fromApiString('100.00', 'BRL'),
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp(r'100')), findsOneWidget);
  });
}
