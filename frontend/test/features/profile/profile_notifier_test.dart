// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/repositories/dashboard_repository.dart';
import 'package:frontend/features/profile/models/profile_model.dart';
import 'package:frontend/features/profile/providers/profile_notifier.dart';
import 'package:frontend/features/profile/providers/profile_repository_provider.dart';
import 'package:frontend/features/profile/repositories/profile_repository.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockHttpClient extends Mock implements http.Client {}

class _MockSupabaseUser extends Mock implements User {}

class _FakeAuthenticatedAuth extends AuthNotifier {
  _FakeAuthenticatedAuth(this._user);
  final User _user;

  int signOutCalls = 0;

  @override
  Future<AuthState> build() async => AuthState.authenticated(user: _user);

  // `deleteAccount` signs out after deletion; the real implementation
  // touches Supabase.instance, which isn't initialized in unit tests.
  @override
  Future<void> signOut() async {
    signOutCalls++;
    state = AsyncData(AuthState.unauthenticated());
  }
}

void main() {
  late _MockSupabaseUser profileAuthUser;

  List<Override> authOverrides() => [
        authNotifierProvider.overrideWith(
          () => _FakeAuthenticatedAuth(profileAuthUser),
        ),
      ];

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    profileAuthUser = _MockSupabaseUser();
    when(() => profileAuthUser.id).thenReturn(
      '11111111-1111-1111-1111-111111111111',
    );
  });

  const profile = ProfileModel(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    email: 'a@b.com',
    displayName: 'Alice',
    avatarUrl: null,
    phone: null,
    defaultCurrency: 'BRL',
    preferredLocale: 'pt_BR',
  );

  const profileUpdated = ProfileModel(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    email: 'a@b.com',
    displayName: 'Bob',
    avatarUrl: null,
    phone: null,
    defaultCurrency: 'BRL',
    preferredLocale: 'pt_BR',
  );

  group('ProfileNotifier', () {
    test('initial state is loading then loads profile', () async {
      final mockRepo = _MockProfileRepository();
      final c = Completer<ProfileModel>();
      when(() => mockRepo.fetchProfile()).thenAnswer((_) => c.future);

      final container = ProviderContainer(
        overrides: [
          ...authOverrides(),
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(profileNotifierProvider).isLoading, isTrue);
      c.complete(profile);
      await container.read(profileNotifierProvider.future);
      expect(
        container.read(profileNotifierProvider).value?.displayName,
        'Alice',
      );
    });

    test('saveProfile calls updateProfile and refreshes state', () async {
      final mockRepo = _MockProfileRepository();
      when(() => mockRepo.fetchProfile()).thenAnswer((_) async => profile);
      when(
        () => mockRepo.updateProfile(any()),
      ).thenAnswer((_) async => profileUpdated);

      final container = ProviderContainer(
        overrides: [
          ...authOverrides(),
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileNotifierProvider.future);
      await container
          .read(profileNotifierProvider.notifier)
          .saveProfile(<String, dynamic>{'display_name': 'Bob'});

      verify(
        () => mockRepo.updateProfile(<String, dynamic>{'display_name': 'Bob'}),
      ).called(1);
      expect(
        container.read(profileNotifierProvider).value?.displayName,
        'Bob',
      );
    });

    test('saveProfile sets error state on API failure', () async {
      final mockRepo = _MockProfileRepository();
      when(() => mockRepo.fetchProfile()).thenAnswer((_) async => profile);
      when(() => mockRepo.updateProfile(any())).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/')),
      );

      final container = ProviderContainer(
        overrides: [
          ...authOverrides(),
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileNotifierProvider.future);
      await container
          .read(profileNotifierProvider.notifier)
          .saveProfile(<String, dynamic>{'display_name': 'X'});

      expect(
        container.read(profileNotifierProvider),
        isA<AsyncError<ProfileModel>>(),
      );
    });

    test(
      'saveProfile invalidates balanceSummaryProvider so next read refetches',
      () async {
        final mockRepo = _MockProfileRepository();
        final mockDashboard = _MockDashboardRepository();
        when(() => mockRepo.fetchProfile()).thenAnswer((_) async => profile);
        when(
          () => mockRepo.updateProfile(any()),
        ).thenAnswer((_) async => profile);

        const summary = BalanceSummaryModel(
          userId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          totalOwed: '1',
          totalOwing: '2',
          netBalance: '-1',
          currency: 'BRL',
        );
        when(() => mockDashboard.fetchBalanceSummary())
            .thenAnswer((_) async => summary);

        final container = ProviderContainer(
          overrides: [
            ...authOverrides(),
            profileRepositoryProvider.overrideWithValue(mockRepo),
            dashboardRepositoryProvider.overrideWithValue(mockDashboard),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileNotifierProvider.future);
        await container.read(balanceSummaryProvider.future);
        await container
            .read(profileNotifierProvider.notifier)
            .saveProfile(<String, dynamic>{'display_name': 'Same'});
        await container.read(balanceSummaryProvider.future);

        verify(() => mockDashboard.fetchBalanceSummary()).called(2);
      },
    );

    test(
      'uploadAvatar: calls getUploadUrl → HTTP PUT → confirmUpload',
      () async {
        final mockRepo = _MockProfileRepository();
        final mockHttp = _MockHttpClient();
        when(() => mockRepo.fetchProfile()).thenAnswer((_) async => profile);
        when(
          () => mockRepo.fetchAvatarUploadUrl(contentType: any(named: 'contentType')),
        ).thenAnswer(
          (_) async => (
            uploadUrl: 'https://upload.example/put',
            fileKey: 'avatars/x.jpg',
          ),
        );
        when(
          () => mockHttp.put(
            any(),
            body: any(named: 'body'),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer(
          (_) async => http.Response('', 200),
        );
        when(() => mockRepo.confirmAvatarUpload('avatars/x.jpg'))
            .thenAnswer((_) async => profile);

        final tmp = await Directory.systemTemp.createTemp('avatar_test');
        addTearDown(() => tmp.delete(recursive: true));
        final file = File('${tmp.path}/a.jpg');
        await file.writeAsBytes(<int>[1, 2, 3]);

        final container = ProviderContainer(
          overrides: [
            ...authOverrides(),
            profileRepositoryProvider.overrideWithValue(mockRepo),
            httpClientProvider.overrideWithValue(mockHttp),
          ],
        );
        addTearDown(container.dispose);
        container.listen(profileNotifierProvider, (_, _) {});

        await container.read(profileNotifierProvider.future);
        await container
            .read(profileNotifierProvider.notifier)
            .uploadAvatar(file);

        verify(
          () => mockRepo.fetchAvatarUploadUrl(contentType: 'image/jpeg'),
        ).called(1);
        verify(
          () => mockHttp.put(
                Uri.parse('https://upload.example/put'),
                body: any(named: 'body'),
                headers: any(named: 'headers'),
              ),
        ).called(1);
        verify(() => mockRepo.confirmAvatarUpload('avatars/x.jpg')).called(1);
      },
    );

    test('uploadAvatar refreshes profile after confirm', () async {
      final mockRepo = _MockProfileRepository();
      final mockHttp = _MockHttpClient();
      when(() => mockRepo.fetchProfile()).thenAnswer((_) async => profile);
      when(
        () => mockRepo.fetchAvatarUploadUrl(contentType: any(named: 'contentType')),
      ).thenAnswer(
        (_) async => (
          uploadUrl: 'https://upload.example/put',
          fileKey: 'k',
        ),
      );
      when(
        () => mockHttp.put(
          any(),
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 200));
      when(() => mockRepo.confirmAvatarUpload('k'))
          .thenAnswer((_) async => profileUpdated);

      final tmp = await Directory.systemTemp.createTemp('avatar_test2');
      addTearDown(() => tmp.delete(recursive: true));
      final file = File('${tmp.path}/a.jpg');
      await file.writeAsBytes(<int>[1]);

      final container = ProviderContainer(
        overrides: [
          ...authOverrides(),
          profileRepositoryProvider.overrideWithValue(mockRepo),
          httpClientProvider.overrideWithValue(mockHttp),
        ],
      );
      addTearDown(container.dispose);
      container.listen(profileNotifierProvider, (_, _) {});

      await container.read(profileNotifierProvider.future);
      await container.read(profileNotifierProvider.notifier).uploadAvatar(file);

      expect(
        container.read(profileNotifierProvider).value?.displayName,
        'Bob',
      );
      verify(() => mockRepo.confirmAvatarUpload('k')).called(1);
    });

    test(
      'uploadAvatar returns false and preserves prior profile on failure',
      () async {
        final mockRepo = _MockProfileRepository();
        final mockHttp = _MockHttpClient();
        when(() => mockRepo.fetchProfile()).thenAnswer((_) async => profile);
        when(
          () => mockRepo.fetchAvatarUploadUrl(
            contentType: any(named: 'contentType'),
          ),
        ).thenThrow(Exception('network error'));

        final tmp = await Directory.systemTemp.createTemp('avatar_test_fail');
        addTearDown(() => tmp.delete(recursive: true));
        final file = File('${tmp.path}/a.jpg');
        await file.writeAsBytes(<int>[1]);

        final container = ProviderContainer(
          overrides: [
            ...authOverrides(),
            profileRepositoryProvider.overrideWithValue(mockRepo),
            httpClientProvider.overrideWithValue(mockHttp),
          ],
        );
        addTearDown(container.dispose);
        container.listen(profileNotifierProvider, (_, _) {});

        await container.read(profileNotifierProvider.future);
        final result = await container
            .read(profileNotifierProvider.notifier)
            .uploadAvatar(file);

        expect(result, isFalse);
        // Prior profile state is preserved, not replaced by an AsyncError —
        // the avatar widget has no error UI, so the caller (a SnackBar) is
        // responsible for surfacing the failure instead.
        expect(
          container.read(profileNotifierProvider).value?.displayName,
          profile.displayName,
        );
        verifyNever(() => mockRepo.confirmAvatarUpload(any()));
      },
    );

    test('deleteAccount calls repo.deleteAccount', () async {
      final mockRepo = _MockProfileRepository();
      when(() => mockRepo.fetchProfile()).thenAnswer((_) async => profile);
      when(() => mockRepo.deleteAccount()).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          ...authOverrides(),
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileNotifierProvider.future);
      await container.read(profileNotifierProvider.notifier).deleteAccount();

      verify(() => mockRepo.deleteAccount()).called(1);
    });
  });
}

class _MockDashboardRepository extends Mock implements DashboardRepository {}
