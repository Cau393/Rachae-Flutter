import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/core/currency/currency_formatter.dart';
import 'package:frontend/features/expenses/models/expense_form_state.dart';
import 'package:frontend/features/expenses/providers/add_expense_notifier.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Split breakdown UI for the add-expense form (equal / exact / % / shares).
///
/// Public API is a [StatelessWidget]; an internal [StatefulWidget] owns
/// [TextEditingController]s for row fields.
class SplitDetailsPanel extends StatelessWidget {
  const SplitDetailsPanel({
    super.key,
    required this.state,
    required this.onAmountChanged,
    required this.onShareChanged,
  });

  final AddExpenseFormState state;
  final void Function(String userId, String amount) onAmountChanged;
  final void Function(String userId, String share) onShareChanged;

  @override
  Widget build(BuildContext context) {
    return _SplitDetailsPanelBody(
      state: state,
      onAmountChanged: onAmountChanged,
      onShareChanged: onShareChanged,
    );
  }
}

class _SplitDetailsPanelBody extends StatefulWidget {
  const _SplitDetailsPanelBody({
    required this.state,
    required this.onAmountChanged,
    required this.onShareChanged,
  });

  final AddExpenseFormState state;
  final void Function(String userId, String amount) onAmountChanged;
  final void Function(String userId, String share) onShareChanged;

  @override
  State<_SplitDetailsPanelBody> createState() => _SplitDetailsPanelBodyState();
}

class _SplitDetailsPanelBodyState extends State<_SplitDetailsPanelBody> {
  List<TextEditingController>? _controllers;
  String _splitMethod = '';
  List<String> _participantIds = const [];

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _SplitDetailsPanelBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final method = widget.state.splitMethod;
    final ids = widget.state.participants.map((p) => p.userId).toList();
    final needReset = method != _splitMethod ||
        ids.length != _participantIds.length ||
        !_listEq(ids, _participantIds);

    if (needReset) {
      _disposeControllers();
      _syncControllers();
    } else if (_controllers != null) {
      final cur = widget.state.currency;
      for (var i = 0; i < widget.state.participants.length; i++) {
        final p = widget.state.participants[i];
        final expected = method == 'exact' ? p.amountOwed : p.shareValue;
        final expectedDisplay =
            CurrencyFormatter.formatRawDecimalForDisplay(expected, cur);
        final currentStored = CurrencyFormatter.normalizeDecimalInput(
          _controllers![i].text,
        );
        if (expected != currentStored) {
          _controllers![i].value = TextEditingValue(
            text: expectedDisplay,
            selection: TextSelection.collapsed(offset: expectedDisplay.length),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _disposeControllers() {
    if (_controllers == null) return;
    for (final c in _controllers!) {
      c.dispose();
    }
    _controllers = null;
  }

  void _syncControllers() {
    _splitMethod = widget.state.splitMethod;
    _participantIds = widget.state.participants.map((p) => p.userId).toList();

    final method = widget.state.splitMethod;
    if (method != 'exact' && method != 'percentage' && method != 'shares') {
      _controllers = null;
      return;
    }

    final cur = widget.state.currency;
    _controllers = List.generate(widget.state.participants.length, (i) {
      final p = widget.state.participants[i];
      final initial = method == 'exact' ? p.amountOwed : p.shareValue;
      return TextEditingController(
        text: CurrencyFormatter.formatRawDecimalForDisplay(initial, cur),
      );
    });
  }

  static Decimal? _parseAmount(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return Decimal.tryParse(normalized);
  }

  static String _sumExactDisplay(List<SplitParticipant> participants) {
    Decimal sum = Decimal.zero;
    for (final p in participants) {
      final d = _parseAmount(p.amountOwed);
      if (d != null) sum += d;
    }
    return sum.toString();
  }

  static Decimal _sumShares(List<SplitParticipant> participants) {
    Decimal sum = Decimal.zero;
    for (final p in participants) {
      final d = _parseAmount(p.shareValue);
      if (d != null) sum += d;
    }
    return sum;
  }

  static final Decimal _hundredD = Decimal.fromInt(100);
  static final Decimal _tolerance = Decimal.parse('0.01');

  String _resolveErrorText(AppLocalizations l10n) {
    final err = widget.state.validationError;
    if (err == null) return '';
    if (err == addExpenseSplitDoesNotMatch) {
      return l10n.addExpenseSplitDoesNotMatch;
    }
    if (err == addExpenseAmountInvalid) {
      return l10n.addExpenseAmountInvalid;
    }
    return err;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final method = widget.state.splitMethod;

    Widget body;
    switch (method) {
      case 'equal':
        body = _EqualPanel(
          participants: widget.state.participants,
          l10n: l10n,
          colorScheme: theme.colorScheme,
        );
        break;
      case 'exact':
        body = _EditableSplitPanel(
          participants: widget.state.participants,
          controllers: _controllers!,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (i, v) =>
              widget.onAmountChanged(widget.state.participants[i].userId, v),
          footer: Text(
            l10n.addExpenseSplitTotalExact(
              CurrencyFormatter.formatRawDecimalForDisplay(
                _sumExactDisplay(widget.state.participants),
                widget.state.currency,
              ),
              CurrencyFormatter.formatRawDecimalForDisplay(
                widget.state.amount,
                widget.state.currency,
              ),
            ),
          ),
        );
        break;
      case 'percentage':
        final sum = _sumShares(widget.state.participants);
        final ok = (sum - _hundredD).abs() < _tolerance;
        final pctText = l10n.addExpenseSplitTotalPercentage(
          CurrencyFormatter.formatRawDecimalForDisplay(
            sum.toString(),
            widget.state.currency,
          ),
        );
        body = _EditableSplitPanel(
          participants: widget.state.participants,
          controllers: _controllers!,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (i, v) =>
              widget.onShareChanged(widget.state.participants[i].userId, v),
          footer: Text(
            pctText,
            style: TextStyle(
              color: ok ? null : theme.colorScheme.error,
            ),
          ),
        );
        break;
      case 'shares':
        body = _EditableSplitPanel(
          participants: widget.state.participants,
          controllers: _controllers!,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (i, v) =>
              widget.onShareChanged(widget.state.participants[i].userId, v),
          footer: null,
        );
        break;
      default:
        body = const SizedBox.shrink();
    }

    final errorText = _resolveErrorText(l10n);
    final showError = widget.state.validationError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}

class _EqualPanel extends StatelessWidget {
  const _EqualPanel({
    required this.participants,
    required this.l10n,
    required this.colorScheme,
  });

  final List<SplitParticipant> participants;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: participants.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = participants[i];
        return ListTile(
          title: Text(p.displayName),
          trailing: Chip(
            label: Text(l10n.addExpenseSplitAutoChip),
            backgroundColor: colorScheme.surfaceContainerHighest,
            side: BorderSide(color: colorScheme.outlineVariant),
            visualDensity: VisualDensity.compact,
          ),
        );
      },
    );
  }
}

class _EditableSplitPanel extends StatelessWidget {
  const _EditableSplitPanel({
    required this.participants,
    required this.controllers,
    required this.keyboardType,
    required this.inputFormatters,
    required this.onChanged,
    this.footer,
  });

  final List<SplitParticipant> participants;
  final List<TextEditingController> controllers;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final void Function(int index, String value) onChanged;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: participants.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = participants[i];
            return ListTile(
              title: Text(p.displayName),
              trailing: SizedBox(
                width: 100,
                child: TextField(
                  controller: controllers[i],
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  decoration: const InputDecoration(isDense: true),
                  onChanged: (v) => onChanged(i, v),
                ),
              ),
            );
          },
        ),
        ?footer,
      ],
    );
  }
}
