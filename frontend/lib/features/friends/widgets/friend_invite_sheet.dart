import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/friends/providers/friend_invite_notifier.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Bottom sheet: generates a shareable invite link (no email/phone input).
class FriendInviteSheet extends ConsumerStatefulWidget {
  const FriendInviteSheet({super.key});

  @override
  ConsumerState<FriendInviteSheet> createState() => _FriendInviteSheetState();
}

class _FriendInviteSheetState extends ConsumerState<FriendInviteSheet> {
  Future<void> _submit(AppLocalizations l10n) async {
    await ref.read(friendInviteNotifierProvider.notifier).sendInvite();
    if (!mounted) {
      return;
    }
    final state = ref.read(friendInviteNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
      return;
    }
    if (!state.hasValue) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${l10n.friendInviteSuccess} ${l10n.friendInviteLinkCopied}',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final inviteAsync = ref.watch(friendInviteNotifierProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.friendInviteTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.friendInviteBody,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: inviteAsync.isLoading ? null : () => _submit(l10n),
              child: inviteAsync.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.friendInviteButton),
            ),
          ],
        ),
      ),
    );
  }
}
