import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/notifications/providers/notification_prefs_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class NotificationPrefsSection extends ConsumerWidget {
  const NotificationPrefsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefsAsync = ref.watch(notificationPrefsProvider);

    return prefsAsync.when(
      data: (prefs) {
        return Column(
          children: [
            SwitchListTile(
              title: Text(l10n.profilePushExpenseCreated),
              value: prefs.pushExpenseCreated,
              onChanged: (v) => ref
                  .read(notificationPrefsProvider.notifier)
                  .updatePreference('push_expense_created', v),
            ),
            SwitchListTile(
              title: Text(l10n.profilePushSettlementRecorded),
              value: prefs.pushSettlementRecorded,
              onChanged: (v) => ref
                  .read(notificationPrefsProvider.notifier)
                  .updatePreference('push_settlement_recorded', v),
            ),
            SwitchListTile(
              title: Text(l10n.profilePushGroupInvitation),
              value: prefs.pushGroupInvitation,
              onChanged: (v) => ref
                  .read(notificationPrefsProvider.notifier)
                  .updatePreference('push_group_invitation', v),
            ),
            SwitchListTile(
              title: Text(l10n.profileEmailExpenseCreated),
              value: prefs.emailExpenseCreated,
              onChanged: (v) => ref
                  .read(notificationPrefsProvider.notifier)
                  .updatePreference('email_expense_created', v),
            ),
            SwitchListTile(
              title: Text(l10n.profileEmailSettlementRecorded),
              value: prefs.emailSettlementRecorded,
              onChanged: (v) => ref
                  .read(notificationPrefsProvider.notifier)
                  .updatePreference('email_settlement_recorded', v),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(l10n.sectionLoadError),
    );
  }
}
