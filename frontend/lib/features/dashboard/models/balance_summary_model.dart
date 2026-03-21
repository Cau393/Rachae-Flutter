import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/currency/money_amount.dart';

@immutable
class BalanceSummaryModel {
  const BalanceSummaryModel({
    required this.totalOwed,
    required this.totalOwing,
    required this.netBalance,
    required this.currency,
  });

  final String totalOwed;
  final String totalOwing;
  final String netBalance;
  final String currency;

  factory BalanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return BalanceSummaryModel(
      totalOwed: json['total_owed'].toString(),
      totalOwing: json['total_owing'].toString(),
      netBalance: json['net_balance'].toString(),
      currency: json['currency'] as String,
    );
  }

  MoneyAmount get totalOwedAsAmount =>
      MoneyAmount.fromApiString(totalOwed, currency);

  MoneyAmount get totalOwingAsAmount =>
      MoneyAmount.fromApiString(totalOwing, currency);

  MoneyAmount get netBalanceAsAmount =>
      MoneyAmount.fromApiString(netBalance, currency);

  bool get isNetPositive => _netDecimal > Decimal.zero;
  bool get isNetNegative => _netDecimal < Decimal.zero;
  bool get isNetZero => _netDecimal == Decimal.zero;

  Decimal get _netDecimal => Decimal.parse(netBalance.trim());

  @override
  bool operator ==(Object other) =>
      other is BalanceSummaryModel &&
      other.totalOwed == totalOwed &&
      other.totalOwing == totalOwing &&
      other.netBalance == netBalance &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(totalOwed, totalOwing, netBalance, currency);
}
