import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';

void main() {
  const sampleJson = {
    'total_owed': '45.00',
    'total_owing': '120.50',
    'net_balance': '-75.50',
    'currency': 'BRL',
  };

  test(
    'fromJson parses total_owed, total_owing, net_balance, and currency',
    () {
      final model = BalanceSummaryModel.fromJson(sampleJson);
      expect(model.totalOwed, '45.00');
      expect(model.totalOwing, '120.50');
      expect(model.netBalance, '-75.50');
      expect(model.currency, 'BRL');
    },
  );

  test(
    'totalOwed, totalOwing, and netBalance are stored as String, not double',
    () {
      final model = BalanceSummaryModel.fromJson(sampleJson);
      expect(model.totalOwed, isA<String>());
      expect(model.totalOwing, isA<String>());
      expect(model.netBalance, isA<String>());
      expect(model.totalOwed, isNot(isA<double>()));
      expect(model.totalOwing, isNot(isA<double>()));
      expect(model.netBalance, isNot(isA<double>()));
    },
  );

  test(
    'totalOwedAsAmount returns MoneyAmount with correct raw and currencyCode',
    () {
      final model = BalanceSummaryModel.fromJson(sampleJson);
      final amount = model.totalOwedAsAmount;
      expect(amount, isA<MoneyAmount>());
      expect(amount.raw, '45.00');
      expect(amount.currencyCode, 'BRL');
    },
  );

  test(
    'totalOwingAsAmount returns MoneyAmount with correct raw and currencyCode',
    () {
      final model = BalanceSummaryModel.fromJson(sampleJson);
      final amount = model.totalOwingAsAmount;
      expect(amount.raw, '120.50');
      expect(amount.currencyCode, 'BRL');
    },
  );

  test(
    'netBalanceAsAmount returns MoneyAmount with correct raw and currencyCode',
    () {
      final model = BalanceSummaryModel.fromJson(sampleJson);
      final amount = model.netBalanceAsAmount;
      expect(amount.raw, '-75.50');
      expect(amount.currencyCode, 'BRL');
    },
  );

  test('isNetNegative is true when net_balance is negative', () {
    final model = BalanceSummaryModel.fromJson(sampleJson);
    expect(model.isNetNegative, isTrue);
    expect(model.isNetPositive, isFalse);
    expect(model.isNetZero, isFalse);
  });

  test('isNetPositive is true when net_balance is positive', () {
    final model = BalanceSummaryModel.fromJson({
      ...sampleJson,
      'net_balance': '99.99',
    });
    expect(model.isNetPositive, isTrue);
    expect(model.isNetNegative, isFalse);
    expect(model.isNetZero, isFalse);
  });

  test('isNetZero is true when net_balance is zero', () {
    final model = BalanceSummaryModel.fromJson({
      ...sampleJson,
      'net_balance': '0.00',
    });
    expect(model.isNetZero, isTrue);
    expect(model.isNetPositive, isFalse);
    expect(model.isNetNegative, isFalse);
  });

  test('equality compares all four fields', () {
    final a = BalanceSummaryModel.fromJson(sampleJson);
    final b = BalanceSummaryModel.fromJson(
      Map<String, dynamic>.from(sampleJson),
    );
    expect(a, equals(b));
    expect(
      a,
      equals(
        BalanceSummaryModel(
          totalOwed: a.totalOwed,
          totalOwing: a.totalOwing,
          netBalance: a.netBalance,
          currency: a.currency,
        ),
      ),
    );
  });

  test('models with different fields are not equal', () {
    final a = BalanceSummaryModel.fromJson(sampleJson);
    final b = BalanceSummaryModel.fromJson({
      ...sampleJson,
      'net_balance': '0.00',
    });
    expect(a, isNot(equals(b)));
  });

  test('fromJson coerces numeric JSON values to String via toString', () {
    final model = BalanceSummaryModel.fromJson({
      'total_owed': 45.0,
      'total_owing': 120.5,
      'net_balance': -75.5,
      'currency': 'BRL',
    });
    expect(model.totalOwed, '45.0');
    expect(model.totalOwing, '120.5');
    expect(model.netBalance, '-75.5');
    expect(model.totalOwedAsAmount.raw, '45.0');
    expect(model.totalOwingAsAmount.raw, '120.5');
    expect(model.netBalanceAsAmount.raw, '-75.5');
    expect(model.currency, 'BRL');
  });
}
