import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/src/config/app_config.dart';

import 'auth_state.dart';

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final client = ref.watch(supabaseClientProvider);
    final session = client.auth.currentSession;

    final initial = session != null
        ? AuthState.authenticated(user: session.user)
        : AuthState.unauthenticated();

    final sub = client.auth.onAuthStateChange.listen((data) {
      switch (data.event) {
        case supa.AuthChangeEvent.signedIn:
        case supa.AuthChangeEvent.tokenRefreshed:
          final s = data.session;
          if (s != null) {
            state = AsyncData(AuthState.authenticated(user: s.user));
          }
          break;
        case supa.AuthChangeEvent.signedOut:
          state = AsyncData(AuthState.unauthenticated());
          break;
        default:
          break;
      }
    });

    ref.onDispose(sub.cancel);

    return initial;
  }

  Future<void> signOut() async {
    state = AsyncLoading<AuthState>();
    final client = ref.read(supabaseClientProvider);
    await client.auth.signOut(scope: supa.SignOutScope.global);
    state = AsyncData(AuthState.unauthenticated());
  }

  Future<void> signInWithGoogle() async {
    final client = ref.read(supabaseClientProvider);
    final redirect = AppConfig.oauthRedirectUri();
    await client.auth.signInWithOAuth(
      supa.OAuthProvider.google,
      redirectTo: redirect,
      authScreenLaunchMode: kIsWeb
          ? supa.LaunchMode.platformDefault
          : supa.LaunchMode.externalApplication,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  Future<void> signInWithApple() async {
    final client = ref.read(supabaseClientProvider);
    final redirect = AppConfig.oauthRedirectUri();
    await client.auth.signInWithOAuth(
      supa.OAuthProvider.apple,
      redirectTo: redirect,
      authScreenLaunchMode: kIsWeb
          ? supa.LaunchMode.platformDefault
          : supa.LaunchMode.externalApplication,
    );
  }
}
