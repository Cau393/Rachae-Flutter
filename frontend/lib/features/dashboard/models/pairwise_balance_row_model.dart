import 'package:flutter/foundation.dart';
import 'package:frontend/core/currency/money_amount.dart';

@immutable
class PairwiseBalanceRowModel {
  const PairwiseBalanceRowModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.balance,
    required this.currency,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String balance;
  final String currency;

  MoneyAmount get balanceAsMoneyAmount =>
      MoneyAmount.fromApiString(balance, currency);

  factory PairwiseBalanceRowModel.fromJson(Map<String, dynamic> json) {
    final u = json['user'] as Map<String, dynamic>;
    return PairwiseBalanceRowModel(
      userId: u['id'].toString(),
      displayName: u['display_name'] as String,
      avatarUrl: u['avatar_url'] as String?,
      balance: json['balance'].toString(),
      currency: json['currency'] as String,
    );
  }
}
