import 'package:flutter/foundation.dart';
import 'package:frontend/core/currency/money_amount.dart';

@immutable
class SettlementSuggestionModel {
  const SettlementSuggestionModel({
    required this.payerId,
    required this.payerName,
    required this.receiverId,
    required this.receiverName,
    required this.amount,
    required this.currency,
  });

  final String payerId;
  final String payerName;
  final String receiverId;
  final String receiverName;
  final String amount;
  final String currency;

  factory SettlementSuggestionModel.fromJson(Map<String, dynamic> json) {
    return SettlementSuggestionModel(
      payerId: json['payer_id'].toString(),
      payerName: json['payer_name'] as String,
      receiverId: json['receiver_id'].toString(),
      receiverName: json['receiver_name'] as String,
      amount: json['amount'].toString(),
      currency: json['currency'] as String,
    );
  }

  MoneyAmount get amountAsMoneyAmount =>
      MoneyAmount.fromApiString(amount, currency);
}
