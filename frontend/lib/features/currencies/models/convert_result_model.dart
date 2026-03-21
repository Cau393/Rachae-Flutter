import 'package:flutter/foundation.dart';

import '../../../core/currency/money_amount.dart';

@immutable
class ConvertResultModel {
  const ConvertResultModel({
    required this.result, // String — NEVER double
    required this.rate, // String — NEVER double
    required this.fetchedAt,
  });

  final String result;
  final String rate;
  final DateTime fetchedAt;

  factory ConvertResultModel.fromJson(Map<String, dynamic> json) =>
      ConvertResultModel(
        result: json['result'].toString(),
        rate: json['rate'].toString(),
        fetchedAt: DateTime.parse(json['fetched_at'] as String),
      );

  /// Creates a MoneyAmount from this result for display.
  MoneyAmount toMoneyAmount(String targetCurrency) =>
      MoneyAmount.fromApiString(result, targetCurrency);
}
