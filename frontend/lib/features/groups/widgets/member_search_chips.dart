import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

typedef _UserOption = ({String id, String displayName});

class MemberSearchChips extends ConsumerStatefulWidget {
  const MemberSearchChips({
    super.key,
    required this.onChanged,
  });

  /// Latest selection is always reported here; duplicate adds do not call this.
  final void Function(List<String> userIds) onChanged;

  @override
  ConsumerState<MemberSearchChips> createState() => _MemberSearchChipsState();
}

class _MemberSearchChipsState extends ConsumerState<MemberSearchChips> {
  List<_UserOption> _selected = [];
  TextEditingController? _fieldController;

  List<String> get selectedUserIds => _selected.map((e) => e.id).toList();

  Future<Iterable<_UserOption>> _optionsBuilder(
    TextEditingValue textEditingValue,
  ) async {
    final q = textEditingValue.text.trim();
    if (q.length < 3) {
      return const Iterable<_UserOption>.empty();
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (_fieldController?.text.trim() != q) {
      return const Iterable<_UserOption>.empty();
    }
    final Dio dio = ref.read(dioProvider);
    final Response<dynamic> response = await dio.get<dynamic>(
      '/users/search/',
      queryParameters: <String, dynamic>{'q': q},
    );
    if (_fieldController?.text.trim() != q) {
      return const Iterable<_UserOption>.empty();
    }
    final Object? data = response.data;
    if (data is! List<dynamic>) {
      return const Iterable<_UserOption>.empty();
    }
    return data.map((dynamic e) {
      final Map<String, dynamic> m = e as Map<String, dynamic>;
      return (
        id: m['id'].toString(),
        displayName: (m['display_name'] as String?) ?? '',
      );
    });
  }

  void _onSelected(_UserOption option) {
    if (_selected.any((x) => x.id == option.id)) {
      return;
    }
    setState(() {
      _selected = [..._selected, option];
    });
    widget.onChanged(selectedUserIds);
    _fieldController?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Autocomplete<_UserOption>(
          displayStringForOption: (_UserOption option) => option.displayName,
          optionsBuilder: _optionsBuilder,
          onSelected: _onSelected,
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            _fieldController = textEditingController;
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: l10n.createGroupMemberSearchHint,
              ),
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selected.map((u) {
            return InputChip(
              label: Text(u.displayName),
              onDeleted: () {
                setState(() {
                  _selected = _selected.where((x) => x.id != u.id).toList();
                });
                widget.onChanged(selectedUserIds);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
