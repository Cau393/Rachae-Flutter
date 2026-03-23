import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/friends/models/friend_balance_model.dart';

void main() {
  test('balance is stored as String, never double', () {
    final m = FriendBalanceModel.fromJson({
      'balance': 12.5,
      'currency': 'BRL',
    });
    expect(m.balance, isA<String>());
    expect(m.balance, isNot(isA<double>()));
    expect(m.balance, '12.5');
    expect(m.currency, 'BRL');
  });

  test('isPositive returns true when balance > 0', () {
    expect(
      FriendBalanceModel.fromJson({
        'balance': '10.00',
        'currency': 'BRL',
      }).isPositive,
      isTrue,
    );
    expect(
      FriendBalanceModel.fromJson({
        'balance': '0.01',
        'currency': 'BRL',
      }).isPositive,
      isTrue,
    );
  });

  test('isNegative returns true when balance < 0', () {
    expect(
      FriendBalanceModel.fromJson({
        'balance': '-5.00',
        'currency': 'BRL',
      }).isNegative,
      isTrue,
    );
  });

  test('isZero returns true for 0.00', () {
    expect(
      FriendBalanceModel.fromJson({
        'balance': '0.00',
        'currency': 'BRL',
      }).isZero,
      isTrue,
    );
    expect(
      FriendBalanceModel.fromJson({
        'balance': '0.00',
        'currency': 'BRL',
      }).isPositive,
      isFalse,
    );
    expect(
      FriendBalanceModel.fromJson({
        'balance': '0.00',
        'currency': 'BRL',
      }).isNegative,
      isFalse,
    );
  });

  test('balanceAsMoneyAmount returns MoneyAmount from balance and currency', () {
    final m = FriendBalanceModel.fromJson({
      'balance': '99.50',
      'currency': 'USD',
    });
    final amt = m.balanceAsMoneyAmount;
    expect(amt, isA<MoneyAmount>());
    expect(amt.raw, '99.50');
    expect(amt.currencyCode, 'USD');
  });
}
