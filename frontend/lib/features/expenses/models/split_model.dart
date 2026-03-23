import 'package:flutter/foundation.dart';
import 'package:frontend/core/currency/money_amount.dart';

@immutable
class SplitModel {
  const SplitModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.amountOwed,
    this.shareValue,
    required this.isSettled,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String amountOwed;
  final String? shareValue;
  final bool isSettled;

  factory SplitModel.fromJson(Map<String, dynamic> json) {
    final shareRaw = json['share_value'];
    return SplitModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      amountOwed: json['amount_owed'].toString(),
      shareValue: shareRaw?.toString(),
      isSettled: json['is_settled'] as bool,
    );
  }

  MoneyAmount amountOwedAsMoneyAmount(String currency) =>
      MoneyAmount.fromApiString(amountOwed, currency);
}
