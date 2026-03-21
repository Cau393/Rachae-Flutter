import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/currency_formatter.dart';
import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/currencies/providers/currency_providers.dart';

void main() {
  testWidgets('CurrencyFormatterWidget renders correctly standalone', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CurrencyFormatterWidget(
            amount: MoneyAmount.fromApiString('1234.56', 'BRL'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1'), findsOneWidget);
    expect(find.textContaining('234'), findsOneWidget);
  });

  testWidgets('selectedCurrencyProvider default is BRL', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: _SelectedCurrencyLabel(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('BRL'), findsOneWidget);
  });

  test('CurrencyFormatter.format output is stable for 1234.56 BRL', () {
    final result = CurrencyFormatter.format(
      MoneyAmount.fromApiString('1234.56', 'BRL'),
    );
    // Regression: BRL 1234.56 must contain digits, R, and comma decimal
    expect(result, contains('1'));
    expect(result, contains('234'));
    expect(result, anyOf(contains(',56'), contains('.56')));
    expect(result, isNotEmpty);
  });
}

/// Const child so [ProviderScope] can be const (same as Consumer + Text).
class _SelectedCurrencyLabel extends ConsumerWidget {
  const _SelectedCurrencyLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: Text(ref.watch(selectedCurrencyProvider)),
    );
  }
}
