import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/currency/money_amount.dart';

@immutable
class GroupSummaryModel {
  const GroupSummaryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.memberCount,
    required this.yourNetBalance,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String type;
  final String currency;
  final int memberCount;
  final String yourNetBalance;
  final DateTime createdAt;

  factory GroupSummaryModel.fromJson(Map<String, dynamic> json) {
    return GroupSummaryModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      type: json['type'] as String,
      currency: json['currency'] as String,
      memberCount: (json['member_count'] as num).toInt(),
      yourNetBalance: json['your_net_balance'].toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static List<GroupSummaryModel> fromJsonList(List<dynamic> json) {
    return json
        .map((e) => GroupSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  MoneyAmount get yourNetBalanceAsAmount =>
      MoneyAmount.fromApiString(yourNetBalance, currency);

  bool get isNetPositive => _netDecimal > Decimal.zero;
  bool get isNetNegative => _netDecimal < Decimal.zero;
  bool get isNetZero => _netDecimal == Decimal.zero;

  Decimal get _netDecimal => Decimal.parse(yourNetBalance.trim());

  @override
  bool operator ==(Object other) =>
      other is GroupSummaryModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
