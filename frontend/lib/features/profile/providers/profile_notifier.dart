import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/profile/models/profile_model.dart';
import 'package:frontend/features/profile/providers/profile_repository_provider.dart';

final profileNotifierProvider =
    AsyncNotifierProvider.autoDispose<ProfileNotifier, ProfileModel>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<ProfileModel> {
  @override
  Future<ProfileModel> build() async {
    final auth = await ref.watch(authNotifierProvider.future);
    if (auth is! AuthStateAuthenticated) {
      throw StateError('Profile requires an authenticated session');
    }
    final profile = await ref.watch(profileRepositoryProvider).fetchProfile();
    return profile;
  }

  Future<void> saveProfile(Map<String, dynamic> fields) async {
    final repo = ref.read(profileRepositoryProvider);
    state = const AsyncLoading<ProfileModel>();
    try {
      state = AsyncData(await repo.updateProfile(fields));
      ref.invalidate(balanceSummaryProvider);
    } catch (e, s) {
      state = AsyncError<ProfileModel>(e, s);
    }
  }

  /// Uploads a new avatar. Returns `true` on success, `false` on failure.
  ///
  /// Errors are surfaced to the caller (rather than only stored in
  /// [AsyncError] state) so the UI can show a visible failure message —
  /// the avatar widget itself only ever renders initials or the image, so a
  /// silent [AsyncError] transition was invisible to the user.
  Future<bool> uploadAvatar(File file) async {
    final repo = ref.read(profileRepositoryProvider);
    final httpClient = ref.read(httpClientProvider);
    final previousState = state;
    try {
      final contentType = _contentType(file);
      final url = await repo.fetchAvatarUploadUrl(contentType: contentType);
      if (!ref.mounted) return false;
      final bytes = await file.readAsBytes();
      if (!ref.mounted) return false;
      final uri = Uri.parse(url.uploadUrl);
      await httpClient.put(
        uri,
        body: bytes,
        headers: <String, String>{'Content-Type': contentType},
      );
      if (!ref.mounted) return false;
      final updated = await repo.confirmAvatarUpload(url.fileKey);
      if (!ref.mounted) return false;
      state = AsyncData(updated);
      ref.invalidate(balanceSummaryProvider);
      return true;
    } catch (_) {
      if (ref.mounted) {
        // Keep showing the previously loaded profile instead of an error
        // screen; the caller is responsible for surfacing the failure (e.g.
        // a SnackBar) since the avatar itself has no error UI.
        state = previousState;
      }
      return false;
    }
  }

  Future<void> deleteAccount() async {
    await ref.read(profileRepositoryProvider).deleteAccount();
    // Sign out here (not in the widget) so the Supabase session is always
    // cleared once the account is gone. Leaving it to the caller's
    // `context.mounted` guard let the token survive on unmount, and the
    // interceptor kept attaching it — firing endless hidden 401 requests
    // against the now-deleted account.
    await ref.read(authNotifierProvider.notifier).signOut();
  }

  static String _contentType(File f) {
    final p = f.path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }
}
