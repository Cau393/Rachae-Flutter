import 'package:flutter/foundation.dart';

import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';
import 'package:frontend/features/expenses/models/split_model.dart';

@immutable
class ExpenseDetailModel {
  const ExpenseDetailModel({
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
    required this.isDeleted,
    required this.createdAt,
    required this.splits,
    required this.receiptUrls,
    required this.createdBy,
    required this.exchangeRateToGroupCurrency,
    required this.deletedAt,
    required this.updatedAt,
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
  final bool isDeleted;
  final DateTime createdAt;
  final List<SplitModel> splits;
  final List<String> receiptUrls;
  final PaidByInfo createdBy;
  final String exchangeRateToGroupCurrency;
  final DateTime? deletedAt;
  final DateTime updatedAt;

  bool isAuthorizedToEdit(String userId) => createdBy.userId == userId;

  MoneyAmount get amountAsMoneyAmount =>
      MoneyAmount.fromApiString(amount, currency);

  factory ExpenseDetailModel.fromJson(Map<String, dynamic> json) {
    final splitsJson = json['splits'] as List<dynamic>? ?? const <dynamic>[];
    final receiptUrlsJson =
        json['receipt_urls'] as List<dynamic>? ?? const <dynamic>[];
    return ExpenseDetailModel(
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
      isDeleted: json['is_deleted'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      splits: splitsJson
          .map((e) => SplitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      receiptUrls: receiptUrlsJson.map((e) => e.toString()).toList(),
      createdBy:
          PaidByInfo.fromJson(json['created_by'] as Map<String, dynamic>),
      exchangeRateToGroupCurrency:
          json['exchange_rate_to_group_currency'].toString(),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
