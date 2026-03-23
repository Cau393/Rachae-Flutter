import 'package:flutter/foundation.dart';
import 'package:frontend/core/currency/money_amount.dart';

@immutable
class PaidByInfo {
  const PaidByInfo({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;

  factory PaidByInfo.fromJson(Map<String, dynamic> json) {
    return PaidByInfo(
      userId: json['id'].toString(),
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

@immutable
class ExpenseListModel {
  const ExpenseListModel({
    required this.id,
    required this.groupId,
    required this.paidBy,
    required this.amount,
    required this.currency,
    required this.amountInGroupCurrency,
    required this.description,
    required this.category,
    required this.expenseDate,
    required this.splitMethod,
    required this.splitCount,
    required this.isDeleted,
    required this.createdAt,
  });

  final String id;
  final String? groupId;
  final PaidByInfo paidBy;
  final String amount;
  final String currency;
  final String amountInGroupCurrency;
  final String description;
  final String category;
  final DateTime expenseDate;
  final String splitMethod;
  final int splitCount;
  final bool isDeleted;
  final DateTime createdAt;

  MoneyAmount get amountAsMoneyAmount =>
      MoneyAmount.fromApiString(amount, currency);

  factory ExpenseListModel.fromJson(Map<String, dynamic> json) {
    return ExpenseListModel(
      id: json['id'].toString(),
      groupId: json['group_id']?.toString(),
      paidBy: PaidByInfo.fromJson(json['paid_by'] as Map<String, dynamic>),
      amount: json['amount'].toString(),
      currency: json['currency'] as String,
      amountInGroupCurrency: json['amount_in_group_currency'].toString(),
      description: json['description'] as String,
      category: json['category'] as String,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      splitMethod: json['split_method'] as String,
      splitCount: json['split_count'] as int,
      isDeleted: json['is_deleted'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseListModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
