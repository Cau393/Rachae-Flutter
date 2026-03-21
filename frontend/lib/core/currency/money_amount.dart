import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

/// Immutable value type for monetary amounts received from the API.
///
/// RULES:
///   - raw is always a String (as received from API, e.g. "125.50")
///   - parsedForDisplay is ONLY for passing to intl NumberFormat — never arithmetic
///   - Use CurrencyFormatterWidget (not toString()) in all Text() widgets
@immutable
class MoneyAmount {
  const MoneyAmount._({required this.raw, required this.currencyCode});

  final String raw;
  final String currencyCode;

  factory MoneyAmount.fromApiString(String amount, String currencyCode) {
    final trimmed = amount.trim();
    assert(trimmed.isNotEmpty, 'MoneyAmount: amount string must not be empty');
    final parsed = Decimal.tryParse(trimmed);
    if (parsed == null) {
      throw ArgumentError('MoneyAmount: "$trimmed" is not a valid decimal string');
    }
    return MoneyAmount._(raw: trimmed, currencyCode: currencyCode.trim());
  }

  /// For use with intl NumberFormat ONLY. Never use for arithmetic.
  double get parsedForDisplay => double.parse(raw);

  bool get isNegative => raw.startsWith('-');
  bool get isZero => Decimal.parse(raw) == Decimal.zero;

  MoneyAmount copyWith({String? raw, String? currencyCode}) => MoneyAmount._(
        raw: raw ?? this.raw,
        currencyCode: currencyCode ?? this.currencyCode,
      );

  @override
  bool operator ==(Object other) =>
      other is MoneyAmount && other.raw == raw && other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(raw, currencyCode);

  /// DEBUG ONLY — never pass to a Text() widget directly.
  @override
  String toString() => 'MoneyAmount($raw $currencyCode)';
}
