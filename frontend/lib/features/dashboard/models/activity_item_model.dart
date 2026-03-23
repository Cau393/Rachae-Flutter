import 'package:flutter/foundation.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';

@immutable
sealed class ActivityItemModel {
  const ActivityItemModel({
    required this.id,
    required this.type,
    required this.groupId,
    required this.groupName,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String? groupId;
  final String? groupName;
  final String amount;
  final String currency;
  final DateTime createdAt;

  MoneyAmount get amountAsMoneyAmount =>
      MoneyAmount.fromApiString(amount, currency);

  factory ActivityItemModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'expense':
        return ExpenseActivity.fromJson(json);
      case 'transaction':
        return TransactionActivity.fromJson(json);
      default:
        throw ArgumentError.value(type, 'type', 'Unknown activity type');
    }
  }

  static List<ActivityItemModel> fromJsonList(List<dynamic> json) => json
      .map((e) => ActivityItemModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

@immutable
final class ExpenseActivity extends ActivityItemModel {
  const ExpenseActivity({
    required super.id,
    required super.type,
    required super.groupId,
    required super.groupName,
    required super.amount,
    required super.currency,
    required super.createdAt,
    required this.description,
    required this.paidById,
    required this.paidByName,
  });

  final String description;
  final String paidById;
  final String paidByName;

  factory ExpenseActivity.fromJson(Map<String, dynamic> json) {
    return ExpenseActivity(
      id: json['id'] as String,
      type: json['type'] as String,
      groupId: json['group_id'] as String?,
      groupName: json['group_name'] as String?,
      amount: json['amount'].toString(),
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String,
      paidById: json['paid_by_id'] as String,
      paidByName: json['paid_by_name'] as String,
    );
  }

  factory ExpenseActivity.fromExpenseListModel(ExpenseListModel m) {
    return ExpenseActivity(
      id: m.id,
      type: 'expense',
      groupId: m.groupId,
      groupName: null,
      amount: m.amount,
      currency: m.currency,
      createdAt: m.createdAt,
      description: m.description,
      paidById: m.paidBy.userId,
      paidByName: m.paidBy.displayName,
    );
  }
}

@immutable
final class TransactionActivity extends ActivityItemModel {
  const TransactionActivity({
    required super.id,
    required super.type,
    required super.groupId,
    required super.groupName,
    required super.amount,
    required super.currency,
    required super.createdAt,
    required this.payerId,
    required this.payerName,
    required this.receiverId,
    required this.receiverName,
    this.note,
    required this.isConfirmed,
  });

  final String payerId;
  final String payerName;
  final String receiverId;
  final String receiverName;
  final String? note;
  final bool isConfirmed;

  factory TransactionActivity.fromJson(Map<String, dynamic> json) {
    return TransactionActivity(
      id: json['id'] as String,
      type: json['type'] as String,
      groupId: json['group_id'] as String?,
      groupName: json['group_name'] as String?,
      amount: json['amount'].toString(),
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      payerId: json['payer_id'] as String,
      payerName: json['payer_name'] as String,
      receiverId: json['receiver_id'] as String,
      receiverName: json['receiver_name'] as String,
      note: json['note'] as String?,
      isConfirmed: json['is_confirmed'] as bool,
    );
  }
}
