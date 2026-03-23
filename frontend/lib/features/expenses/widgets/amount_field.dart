import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/core/currency/currency_formatter.dart';

/// Hero-style amount entry: large centered field, currency symbol prefix,
/// optional converted-amount preview line (call sites pass the final string,
/// e.g. from `context.l10n.addExpenseConvertedPreview`).
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.value,
    required this.currency,
    required this.onChanged,
    this.convertedPreview,
    /// Currency of [convertedPreview] (group currency); used for BRL comma display.
    this.convertedPreviewCurrency,
  });

  final String value;
  final String currency;
  final ValueChanged<String> onChanged;
  final String? convertedPreview;
  final String? convertedPreviewCurrency;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _controller;

  static final RegExp _allowedPattern = RegExp(r'^[-]?[0-9]*([.,][0-9]*)?$');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: CurrencyFormatter.formatRawDecimalForDisplay(
        widget.value,
        widget.currency,
      ),
    );
  }

  @override
  void didUpdateWidget(AmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final display = CurrencyFormatter.formatRawDecimalForDisplay(
      widget.value,
      widget.currency,
    );
    final currentStored =
        CurrencyFormatter.normalizeDecimalInput(_controller.text);
    if (widget.value != currentStored) {
      _controller.value = TextEditingValue(
        text: display,
        selection: TextSelection.collapsed(offset: display.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String raw) {
    widget.onChanged(CurrencyFormatter.normalizeDecimalInput(raw));
  }

  String? _previewDisplay() {
    final p = widget.convertedPreview;
    if (p == null) return null;
    final c = widget.convertedPreviewCurrency ?? widget.currency;
    return CurrencyFormatter.formatRawDecimalForDisplay(p, c);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                CurrencyFormatter.symbolFor(widget.currency),
                style: TextStyle(
                  fontSize: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [
                  _DecimalAmountInputFormatter(_allowedPattern),
                ],
                onChanged: _handleChanged,
              ),
            ),
          ],
        ),
        if (widget.convertedPreview != null)
          Text(
            _previewDisplay()!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Allows optional leading minus, digits, and at most one decimal separator
/// (`,` or `.`). Rejects letters and multiple separators.
class _DecimalAmountInputFormatter extends TextInputFormatter {
  _DecimalAmountInputFormatter(this._pattern);

  final RegExp _pattern;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }
    if (_pattern.hasMatch(text)) {
      return newValue;
    }
    return oldValue;
  }
}
