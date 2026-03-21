import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/money_amount.dart';

void main() {
  group('construction', () {
    test('fromApiString creates from a valid API string', () {
      final m = MoneyAmount.fromApiString('125.50', 'BRL');
      expect(m.raw, '125.50');
      expect(m.currencyCode, 'BRL');
    });

    test('fromApiString trims leading and trailing whitespace', () {
      final m = MoneyAmount.fromApiString('  30.00  ', 'USD');
      expect(m.raw, '30.00');
    });

    test('zero is a valid amount', () {
      final m = MoneyAmount.fromApiString('0.00', 'BRL');
      expect(m.raw, '0.00');
    });

    test('negative amount is valid (used for debt display)', () {
      final m = MoneyAmount.fromApiString('-45.99', 'BRL');
      expect(m.raw, '-45.99');
    });

    test('throws AssertionError for empty string', () {
      expect(
        () => MoneyAmount.fromApiString('', 'BRL'),
        throwsAssertionError,
      );
    });

    test('throws ArgumentError for non-numeric string', () {
      expect(
        () => MoneyAmount.fromApiString('abc', 'BRL'),
        throwsArgumentError,
      );
    });
  });

  group('parsedForDisplay', () {
    test('parses to double for intl NumberFormat use only', () {
      final m = MoneyAmount.fromApiString('125.50', 'BRL');
      // parsedForDisplay is ONLY for passing to intl NumberFormat
      expect(m.parsedForDisplay, closeTo(125.50, 0.001));
    });

    test('negative amount parses correctly', () {
      final m = MoneyAmount.fromApiString('-30.00', 'BRL');
      expect(m.parsedForDisplay, closeTo(-30.00, 0.001));
    });
  });

  group('computed booleans', () {
    test('isNegative is true for negative amounts', () {
      final m = MoneyAmount.fromApiString('-10.00', 'BRL');
      expect(m.isNegative, isTrue);
    });

    test('isNegative is false for positive amounts', () {
      expect(
        MoneyAmount.fromApiString('10.00', 'BRL').isNegative,
        isFalse,
      );
    });

    test('isZero is true for 0.00', () {
      expect(
        MoneyAmount.fromApiString('0.00', 'BRL').isZero,
        isTrue,
      );
    });
  });

  group('equality and identity', () {
    test('two identical MoneyAmounts are equal (same raw and code)', () {
      final a = MoneyAmount.fromApiString('50.00', 'BRL');
      final b = MoneyAmount.fromApiString('50.00', 'BRL');
      expect(a, equals(b));
    });

    test('different currencies are not equal', () {
      final a = MoneyAmount.fromApiString('50.00', 'BRL');
      final b = MoneyAmount.fromApiString('50.00', 'USD');
      expect(a, isNot(equals(b)));
    });
  });

  group('copyWith', () {
    test('copyWith changes only currency code', () {
      final original = MoneyAmount.fromApiString('100.00', 'BRL');
      final copy = original.copyWith(currencyCode: 'USD');
      expect(copy.raw, '100.00');
      expect(copy.currencyCode, 'USD');
    });

    test('copyWith changes only raw amount', () {
      final original = MoneyAmount.fromApiString('100.00', 'BRL');
      final copy = original.copyWith(raw: '200.00');
      expect(copy.raw, '200.00');
      expect(copy.currencyCode, 'BRL');
    });
  });

  group('toString', () {
    test('toString is a debug sentinel — contains raw and code', () {
      // IMPORTANT: toString() is for debugging ONLY.
      // Never pass MoneyAmount.toString() directly to a Text() widget.
      // Always use CurrencyFormatterWidget.
      expect(
        MoneyAmount.fromApiString('99.99', 'BRL').toString(),
        contains('99.99'),
      );
    });
  });
}
