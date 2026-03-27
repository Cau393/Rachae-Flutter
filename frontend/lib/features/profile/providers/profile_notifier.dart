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
    return ref.watch(profileRepositoryProvider).fetchProfile();
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

  Future<void> uploadAvatar(File file) async {
    final repo = ref.read(profileRepositoryProvider);
    final httpClient = ref.read(httpClientProvider);
    try {
      final contentType = _contentType(file);
      final url = await repo.fetchAvatarUploadUrl(contentType: contentType);
      if (!ref.mounted) return;
      final bytes = await file.readAsBytes();
      if (!ref.mounted) return;
      final uri = Uri.parse(url.uploadUrl);
      await httpClient.put(
        uri,
        body: bytes,
        headers: <String, String>{'Content-Type': contentType},
      );
      if (!ref.mounted) return;
      final updated = await repo.confirmAvatarUpload(url.fileKey);
      if (!ref.mounted) return;
      state = AsyncData(updated);
      ref.invalidate(balanceSummaryProvider);
    } catch (e, s) {
      if (!ref.mounted) return;
      state = AsyncError<ProfileModel>(e, s);
    }
  }

  Future<void> deleteAccount() async {
    await ref.read(profileRepositoryProvider).deleteAccount();
  }

  static String _contentType(File f) {
    final p = f.path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }
}
