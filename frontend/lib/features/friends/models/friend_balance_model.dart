import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/currency/money_amount.dart';

@immutable
class FriendBalanceModel {
  const FriendBalanceModel({
    required this.balance,
    required this.currency,
  });

  /// Raw balance string from the API (coerced with `.toString()` in [fromJson]).
  final String balance;
  final String currency;

  factory FriendBalanceModel.fromJson(Map<String, dynamic> json) {
    return FriendBalanceModel(
      balance: json['balance'].toString(),
      currency: json['currency'] as String,
    );
  }

  MoneyAmount get balanceAsMoneyAmount =>
      MoneyAmount.fromApiString(balance, currency);

  Decimal get _balanceDecimal => Decimal.parse(balance.trim());

  bool get isPositive => _balanceDecimal > Decimal.zero;

  bool get isNegative => _balanceDecimal < Decimal.zero;

  bool get isZero => _balanceDecimal == Decimal.zero;
}
