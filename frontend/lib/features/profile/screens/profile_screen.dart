import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/groups/widgets/currency_dropdown.dart';
import 'package:frontend/features/profile/providers/profile_notifier.dart';
import 'package:frontend/features/profile/widgets/avatar_editor.dart';
import 'package:frontend/features/profile/widgets/danger_zone_section.dart';
import 'package:frontend/features/profile/widgets/legal_links_section.dart';
import 'package:frontend/features/profile/widgets/notification_prefs_section.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.profileLoadError, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(profileNotifierProvider),
                  child: Text(l10n.retryLabel),
                ),
              ],
            ),
          ),
        ),
        data: (profile) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: Padding(
                padding: EdgeInsets.only(top: 16),
                child: AvatarEditor(),
              )),
              const SizedBox(height: 16),
              ListTile(
                title: Text(l10n.profileDisplayNameLabel),
                subtitle: Text(
                  profile.displayNameFromEmail.isEmpty
                      ? profile.email
                      : profile.displayNameFromEmail,
                ),
              ),
              ListTile(
                title: Text(l10n.profileEmailLabel),
                subtitle: Text(profile.email),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CurrencyDropdown(
                  value: profile.defaultCurrency,
                  currencyLabel: l10n.profileDefaultCurrencyLabel,
                  onChanged: (code) {
                    ref.read(profileNotifierProvider.notifier).saveProfile(
                          <String, dynamic>{'default_currency': code},
                        );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  l10n.profileNotificationsSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const NotificationPrefsSection(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(l10n.profileExportButton),
                onTap: () => context.push('/profile/export'),
              ),
              const Divider(),
              const LegalLinksSection(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.profileSignOutButton),
                onTap: () => _confirmSignOut(context, ref, l10n),
              ),
              const Divider(),
              const DangerZoneSection(),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmSignOut(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.profileSignOutButton),
      content: Text(l10n.profileSignOutConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.profileSignOutButton),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(authNotifierProvider.notifier).signOut();
  }
}
