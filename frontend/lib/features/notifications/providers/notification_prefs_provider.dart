import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/notifications/models/notification_preference_model.dart';
import 'package:frontend/features/notifications/providers/notifications_repository_provider.dart';

final notificationPrefsProvider =
    AsyncNotifierProvider.autoDispose<NotificationPrefsNotifier,
        NotificationPreferenceModel>(
  NotificationPrefsNotifier.new,
);

class NotificationPrefsNotifier
    extends AsyncNotifier<NotificationPreferenceModel> {
  @override
  Future<NotificationPreferenceModel> build() {
    return ref.read(notificationsRepositoryProvider).fetchPreferences();
  }

  Future<void> updatePreference(String fieldKey, bool value) async {
    await ref
        .read(notificationsRepositoryProvider)
        .updatePreferences(<String, dynamic>{fieldKey: value});
    ref.invalidateSelf();
  }
}
