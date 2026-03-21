import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';

class MockSupabaseClient extends Mock implements supa.SupabaseClient {}

class MockGoTrueClient extends Mock implements supa.GoTrueClient {}

class MockSession extends Mock implements supa.Session {}

class MockUser extends Mock implements supa.User {}

void main() {
  setUpAll(() {
    registerFallbackValue(supa.SignOutScope.local);
    registerFallbackValue(supa.SignOutScope.global);
  });

  group('AuthNotifier', () {
    test('resolves to unauthenticated when session is null after build',
        () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(null);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => Stream<supa.AuthState>.empty(),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);

      expect(
        container.read(authNotifierProvider),
        const AsyncData(AuthState.unauthenticated()),
      );
    });

    test('build() emits authenticated when Supabase session exists', () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final session = MockSession();
      final user = MockUser();
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.user).thenReturn(user);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => Stream<supa.AuthState>.empty(),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);

      final async = container.read(authNotifierProvider);
      expect(async, isA<AsyncData<AuthState>>());
      expect(async.requireValue, isA<AuthStateAuthenticated>());
      expect((async.requireValue as AuthStateAuthenticated).user, isNotNull);
    });

    test('build() emits unauthenticated when session is null', () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(null);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => Stream<supa.AuthState>.empty(),
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);

      expect(
        container.read(authNotifierProvider),
        const AsyncData(AuthState.unauthenticated()),
      );
    });

    test('signOut() calls supabase.auth.signOut and emits unauthenticated',
        () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(null);
      when(() => mockAuth.onAuthStateChange).thenAnswer(
        (_) => Stream<supa.AuthState>.empty(),
      );
      when(() => mockAuth.signOut(scope: any(named: 'scope')))
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).signOut();

      verify(() => mockAuth.signOut(scope: supa.SignOutScope.global)).called(1);
      expect(
        container.read(authNotifierProvider),
        const AsyncData(AuthState.unauthenticated()),
      );
    });

    test('onAuthStateChange stream drives state transitions', () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final session = MockSession();
      final user = MockUser();
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(null);
      when(() => session.user).thenReturn(user);

      final streamController = StreamController<supa.AuthState>();
      when(() => mockAuth.onAuthStateChange).thenAnswer((_) {
        return streamController.stream;
      });

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
      );
      addTearDown(container.dispose);

      final states = <AuthState>[];
      final subscription = container.listen<AsyncValue<AuthState>>(
        authNotifierProvider,
        (previous, next) => next.whenData(states.add),
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container.read(authNotifierProvider.future);

      streamController.add(
        supa.AuthState(supa.AuthChangeEvent.signedIn, session),
      );
      streamController.add(
        supa.AuthState(supa.AuthChangeEvent.signedOut, null),
      );

      await Future<void>.delayed(Duration.zero);

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states[states.length - 2], isA<AuthStateAuthenticated>());
      expect(states.last, AuthState.unauthenticated());
    });
  });
}
