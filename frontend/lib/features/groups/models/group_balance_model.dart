import 'package:flutter/foundation.dart';
import 'package:frontend/core/currency/money_amount.dart';

@immutable
class GroupBalanceModel {
  const GroupBalanceModel({
    required this.userId,
    required this.displayName,
    required this.netBalance,
  });

  final String userId;
  final String displayName;
  final String netBalance;

  factory GroupBalanceModel.fromJson(Map<String, dynamic> json) {
    return GroupBalanceModel(
      userId: json['user_id'].toString(),
      displayName: json['display_name'] as String,
      netBalance: json['net_balance'].toString(),
    );
  }

  MoneyAmount netBalanceAsAmount(String currency) =>
      MoneyAmount.fromApiString(netBalance, currency);
}
