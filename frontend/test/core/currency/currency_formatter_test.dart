import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/currency_formatter.dart';
import 'package:frontend/core/currency/money_amount.dart';

void main() {
  group('CurrencyFormatter.format — BRL pt_BR locale', () {
    test('positive BRL amount contains currency indicator and digits', () {
      final result = CurrencyFormatter.format(
        MoneyAmount.fromApiString('125.50', 'BRL'),
      );
      expect(result, contains('125'));
      expect(result, anyOf(contains('R'), contains(r'$')));
      expect(result, anyOf(contains(',50'), contains('.50')));
    });

    test('zero BRL formats with two decimal places', () {
      final result = CurrencyFormatter.format(
        MoneyAmount.fromApiString('0.00', 'BRL'),
      );
      expect(result, anyOf(contains(',00'), contains('.00')));
    });

    test('large amount 1000.00 formats with separators', () {
      final result = CurrencyFormatter.format(
        MoneyAmount.fromApiString('1000.00', 'BRL'),
      );
      expect(result, contains('1'));
      expect(result, contains('000'));
    });

    test('negative amount is visually distinct (contains - or parentheses)', () {
      final result = CurrencyFormatter.format(
        MoneyAmount.fromApiString('-45.99', 'BRL'),
      );
      expect(result, anyOf(contains('-'), contains('(')));
    });

    test('always shows exactly 2 decimal places — no truncation', () {
      final result = CurrencyFormatter.format(
        MoneyAmount.fromApiString('10.00', 'BRL'),
      );
      // Must NOT produce 'R$ 10' — always 'R$ 10,00'
      expect(result, anyOf(contains(',00'), contains('.00')));
    });
  });

  group('CurrencyFormatter.format — USD', () {
    test('USD amount contains dollar sign indicator', () {
      final result = CurrencyFormatter.format(
        MoneyAmount.fromApiString('99.99', 'USD'),
      );
      expect(result, contains('99'));
      expect(result, anyOf(contains(r'$'), contains('US')));
    });
  });

  group('CurrencyFormatter.format — EUR', () {
    test('EUR amount is non-empty and contains amount digits', () {
      final result = CurrencyFormatter.format(
        MoneyAmount.fromApiString('50.00', 'EUR'),
      );
      expect(result, contains('50'));
      expect(result, isNotEmpty);
    });
  });

  group('CurrencyFormatter.format — unknown currency code', () {
    test("unknown code 'XYZ' falls back gracefully without throwing", () {
      final result = CurrencyFormatter.format(
        MoneyAmount.fromApiString('10.00', 'XYZ'),
      );
      expect(result, isA<String>());
      expect(result, isNotEmpty);
      expect(result, contains('XYZ'));
    });
  });

  group('CurrencyFormatter.formatCompact', () {
    test('compact format for 1500.00 BRL is shorter than full format', () {
      final compact = CurrencyFormatter.formatCompact(
        MoneyAmount.fromApiString('1500.00', 'BRL'),
      );
      final full = CurrencyFormatter.format(
        MoneyAmount.fromApiString('1500.00', 'BRL'),
      );
      expect(compact, isA<String>());
      expect(compact.length, lessThan(full.length));
    });
  });

  group('CurrencyFormatter.formatSign', () {
    test('positive amount gets + prefix', () {
      final result = CurrencyFormatter.formatSign(
        MoneyAmount.fromApiString('50.00', 'BRL'),
      );
      expect(result, startsWith('+'));
    });

    test('negative amount starts with minus (already in formatted result)', () {
      final result = CurrencyFormatter.formatSign(
        MoneyAmount.fromApiString('-30.00', 'BRL'),
      );
      expect(result, anyOf(startsWith('-'), startsWith('−')));
    });

    test('zero amount has no + prefix', () {
      final result = CurrencyFormatter.formatSign(
        MoneyAmount.fromApiString('0.00', 'BRL'),
      );
      expect(result, isNot(startsWith('+')));
    });
  });

  group('CurrencyFormatter.formatRawDecimalForDisplay', () {
    test('BRL replaces dot with comma for decimals', () {
      expect(
        CurrencyFormatter.formatRawDecimalForDisplay('10.50', 'BRL'),
        '10,50',
      );
    });

    test('non-BRL leaves raw string unchanged', () {
      expect(
        CurrencyFormatter.formatRawDecimalForDisplay('10.50', 'USD'),
        '10.50',
      );
    });
  });

  group('CurrencyFormatter.normalizeDecimalInput', () {
    test('comma becomes dot for API', () {
      expect(CurrencyFormatter.normalizeDecimalInput('150,50'), '150.50');
    });

    test('trims whitespace', () {
      expect(CurrencyFormatter.normalizeDecimalInput('  10.5  '), '10.5');
    });
  });

  group('CurrencyFormatter.symbolFor', () {
    test('BRL symbol is R\$', () {
      expect(CurrencyFormatter.symbolFor('BRL'), equals(r'R$'));
    });

    test('USD symbol contains \$', () {
      expect(
        CurrencyFormatter.symbolFor('USD'),
        anyOf(equals(r'$'), equals(r'US$')),
      );
    });

    test('unknown code returns the code itself as fallback', () {
      expect(CurrencyFormatter.symbolFor('XYZ'), equals('XYZ'));
    });
  });
}
