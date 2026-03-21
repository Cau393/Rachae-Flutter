import 'package:flutter/foundation.dart';

@immutable
class ExchangeRateModel {
  const ExchangeRateModel({
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.rate, // String — NEVER double
    required this.fetchedAt,
  });

  final String baseCurrency;
  final String quoteCurrency;
  final String rate; // "0.200000" — always coerced from JSON to String
  final DateTime fetchedAt;

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) =>
      ExchangeRateModel(
        baseCurrency: json['base_currency'] as String,
        quoteCurrency: json['quote_currency'] as String,
        rate: json['rate'].toString(), // coerce to String even if JSON sends a number
        fetchedAt: DateTime.parse(json['fetched_at'] as String),
      );

  static List<ExchangeRateModel> fromJsonList(List<dynamic> json) =>
      json.map((e) => ExchangeRateModel.fromJson(e as Map<String, dynamic>)).toList();
}
