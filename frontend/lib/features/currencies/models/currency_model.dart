import 'package:flutter/foundation.dart';

import '../../../core/currency/currency_formatter.dart';

@immutable
class CurrencyModel {
  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;

  factory CurrencyModel.fromJson(Map<String, dynamic> json) => CurrencyModel(
        code: json['code'] as String,
        name: json['name'] as String,
        symbol: (json['symbol'] as String?) ?? (json['code'] as String),
      );

  factory CurrencyModel.brl() => CurrencyModel(
        code: 'BRL', // ignore: hardcoded — ISO 4217 code for factory
        name: 'Real Brasileiro',
        symbol: CurrencyFormatter.symbolFor('BRL'), // ignore: hardcoded — ISO 4217
      );

  Map<String, dynamic> toJson() => {'code': code, 'name': name, 'symbol': symbol};

  static List<CurrencyModel> fromJsonList(List<dynamic> json) =>
      json.map((e) => CurrencyModel.fromJson(e as Map<String, dynamic>)).toList();

  @override
  bool operator ==(Object other) => other is CurrencyModel && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'CurrencyModel($code)';
}
