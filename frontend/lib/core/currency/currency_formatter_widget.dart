import 'package:flutter/material.dart';

import 'currency_formatter.dart';
import 'money_amount.dart';

/// The ONLY widget that should display monetary amounts in this app.
///
/// CORRECT:  CurrencyFormatterWidget(amount: MoneyAmount.fromApiString('50.00', 'BRL'))
/// FORBIDDEN: Text(expense.amount.toString())
/// FORBIDDEN: Text('R\$ ${expense.amount}')
class CurrencyFormatterWidget extends StatelessWidget {
  const CurrencyFormatterWidget({
    super.key,
    required this.amount,
    this.style,
    this.compact = false,
    this.showSign = false,
    this.colorCoded = false,
    this.textAlign,
  });

  final MoneyAmount amount;

  /// Optional TextStyle override. When colorCoded=true, the color
  /// in this style is replaced by the computed color.
  final TextStyle? style;

  /// Use compact format (e.g. R$1,5 mil) for tight spaces.
  final bool compact;

  /// Show explicit + or − sign prefix for balance displays.
  final bool showSign;

  /// Apply green for positive, red (colorScheme.error) for negative,
  /// neutral (onSurfaceVariant) for zero.
  final bool colorCoded;

  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final String displayText = showSign
        ? CurrencyFormatter.formatSign(amount)
        : compact
            ? CurrencyFormatter.formatCompact(amount)
            : CurrencyFormatter.format(amount);

    TextStyle? effectiveStyle = style;

    if (colorCoded) {
      final colorScheme = Theme.of(context).colorScheme;
      final Color amountColor = amount.isNegative
          ? colorScheme.error
          : amount.isZero
              ? colorScheme.onSurfaceVariant
              : const Color(0xFF2E7D32); // Material green 800
      effectiveStyle = (style ?? const TextStyle()).copyWith(color: amountColor);
    }

    return Semantics(
      label: displayText,
      child: Text(
        displayText,
        style: effectiveStyle,
        textAlign: textAlign,
      ),
    );
  }
}
