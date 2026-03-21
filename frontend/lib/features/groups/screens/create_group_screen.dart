import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/groups/providers/group_create_notifier.dart';
import 'package:frontend/features/groups/widgets/currency_dropdown.dart';
import 'package:frontend/features/groups/widgets/group_type_selector.dart';
import 'package:frontend/features/groups/widgets/simplify_debts_toggle.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _type = 'other';
  String _currency = 'BRL'; // ignore: hardcoded — MVP default ISO 4217 (see .cursorrules)
  bool _simplifyDebts = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final id = await ref.read(groupCreateNotifierProvider.notifier).submit({
      'name': _nameController.text.trim(),
      'type': _type,
      'currency': _currency,
      'simplify_debts': _simplifyDebts,
      'member_ids': <String>[],
    });

    if (!mounted) return;

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.createGroupSuccess)),
      );
      if (!mounted) return;
      context.go('/groups/$id');
      return;
    }

    if (ref.read(groupCreateNotifierProvider).hasError) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.createGroupError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final submitting = ref.watch(groupCreateNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createGroupTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.createGroupNameLabel,
                hintText: l10n.createGroupNameHint,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.requiredFieldError;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CurrencyDropdown(
              value: _currency,
              onChanged: (v) => setState(() => _currency = v),
            ),
            const SizedBox(height: 16),
            GroupTypeSelector(
              value: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 8),
            SimplifyDebtsToggle(
              value: _simplifyDebts,
              onChanged: (v) => setState(() => _simplifyDebts = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: submitting ? null : () => _submit(l10n),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (submitting) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(l10n.createGroupButton),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
