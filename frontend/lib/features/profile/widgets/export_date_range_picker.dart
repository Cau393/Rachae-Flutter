import 'package:flutter/material.dart';

import 'package:frontend/src/l10n/generated/app_localizations.dart';

class ExportDateRangePicker extends StatefulWidget {
  const ExportDateRangePicker({
    super.key,
    required this.onChanged,
  });

  final void Function(DateTime? from, DateTime? to) onChanged;

  @override
  State<ExportDateRangePicker> createState() => _ExportDateRangePickerState();
}

class _ExportDateRangePickerState extends State<ExportDateRangePicker> {
  DateTime? _from;
  DateTime? _to;

  void _emit() => widget.onChanged(_from, _to);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        ListTile(
          title: Text(l10n.exportDateFromLabel),
          subtitle: Text(
            _from == null ? '-' : _from!.toIso8601String().split('T').first,
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _from ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                _from = picked;
                if (_to != null && _to!.isBefore(_from!)) {
                  _to = _from;
                }
              });
              _emit();
            }
          },
        ),
        ListTile(
          title: Text(l10n.exportDateToLabel),
          subtitle: Text(
            _to == null ? '-' : _to!.toIso8601String().split('T').first,
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _to ?? _from ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                _to = picked;
                if (_from != null && _from!.isAfter(_to!)) {
                  _from = _to;
                }
              });
              _emit();
            }
          },
        ),
      ],
    );
  }
}
