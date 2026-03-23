import 'package:intl/intl.dart';

import 'money_amount.dart';

class CurrencyFormatter {
  CurrencyFormatter._(); // utility class — no instantiation

  static const String _defaultLocale = 'pt_BR';

  /// Full format: symbol + amount with 2 decimal places.
  /// Example: MoneyAmount('125.50', 'BRL') → 'R$\u00a0125,50'
  static String format(MoneyAmount amount) {
    try {
      final formatter = NumberFormat.currency(
        locale: _localeFor(amount.currencyCode),
        symbol: symbolFor(amount.currencyCode),
        decimalDigits: 2,
      );
      return formatter.format(amount.parsedForDisplay);
    } catch (_) {
      return '${amount.currencyCode}\u00a0${amount.raw}';
    }
  }

  /// Compact format for tight spaces (balance chips, card subtitles).
  /// Example: 1500.00 BRL → 'R$\u00a01,5 mil'
  static String formatCompact(MoneyAmount amount) {
    try {
      final formatter = NumberFormat.compactCurrency(
        locale: _localeFor(amount.currencyCode),
        symbol: symbolFor(amount.currencyCode),
        decimalDigits: 1,
      );
      return formatter.format(amount.parsedForDisplay);
    } catch (_) {
      return format(amount);
    }
  }

  /// Signed format for balance displays.
  /// Positive gets + prefix. Negative already has − from NumberFormat. Zero has no sign.
  static String formatSign(MoneyAmount amount) {
    if (amount.isZero) return format(amount);
    final formatted = format(amount);
    if (amount.isNegative) return formatted;
    return '+$formatted';
  }

  /// Returns the currency symbol for an ISO 4217 code.
  /// Fallback: returns the code itself for unknown currencies.
  static String symbolFor(String currencyCode) {
    const symbols = <String, String>{
      'BRL': r'R$',
      'USD': r'US$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'ARS': r'ARS$',
      'CLP': r'CLP$',
      'COP': r'COP$',
      'MXN': r'MX$',
      'PEN': 'S/',
      'UYU': r'$U',
      'CAD': r'CA$',
      'AUD': r'A$',
      'CHF': 'CHF',
      'CNY': '¥',
    };
    return symbols[currencyCode] ?? currencyCode;
  }

  static String _localeFor(String currencyCode) {
    const locales = <String, String>{
      'BRL': 'pt_BR',
      'USD': 'en_US',
      'EUR': 'de_DE',
      'GBP': 'en_GB',
      'JPY': 'ja_JP',
      'ARS': 'es_AR',
      'CLP': 'es_CL',
      'MXN': 'es_MX',
      'PEN': 'es_PE',
      'CAD': 'en_CA',
      'AUD': 'en_AU',
    };
    return locales[currencyCode] ?? _defaultLocale;
  }

  /// Raw decimal strings from the API/state use `.` (e.g. `"10.50"`).
  /// For BRL, show `,` as the decimal separator in text fields and inline labels.
  /// Does not change stored/submitted values — pair with [normalizeDecimalInput].
  static String formatRawDecimalForDisplay(String raw, String currencyCode) {
    if (currencyCode != 'BRL') return raw;
    return raw.replaceAll('.', ',');
  }

  /// Normalizes typed input for API/state: `,` → `.` (Brazilian keyboard).
  static String normalizeDecimalInput(String raw) =>
      raw.trim().replaceAll(',', '.');
}
