import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/profile/providers/profile_notifier.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class DangerZoneSection extends ConsumerWidget {
  const DangerZoneSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.profileDeleteAccountButton),
                  content: Text(l10n.profileDeleteAccountConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.cancelLabel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(l10n.profileDeleteAccountButton),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await ref.read(profileNotifierProvider.notifier).deleteAccount();
                if (context.mounted) {
                  await ref.read(authNotifierProvider.notifier).signOut();
                }
              }
            },
            child: Text(l10n.profileDeleteAccountButton),
          ),
        ],
      ),
    );
  }
}
