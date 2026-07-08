import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/core/revenuecat/revenuecat.dart';
import 'package:frontend/src/config/app_config.dart';

import 'auth_state.dart';
import 'pending_friend_invite_token_storage.dart';

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
    unawaited(revenueCatLogOut());
    await client.auth.signOut(scope: supa.SignOutScope.global);
    state = AsyncData(AuthState.unauthenticated());
  }

  Future<void> signInWithGoogle({String? inviteToken}) async {
    final client = ref.read(supabaseClientProvider);
    final redirect = AppConfig.oauthRedirectUri();
    persistPendingFriendInviteToken(inviteToken);
    // Use platform default on iOS (in-app browser). Full Safari
    // (`externalApplication`) often fails to open custom-scheme OAuth redirects.
    // supabase_flutter already forces external browser for Google on Android.
    await client.auth.signInWithOAuth(
      supa.OAuthProvider.google,
      redirectTo: redirect,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  Future<void> signInWithApple({String? inviteToken}) async {
    final client = ref.read(supabaseClientProvider);
    persistPendingFriendInviteToken(inviteToken);
    // On iOS, use the native Sign in with Apple sheet + Supabase
    // signInWithIdToken. The browser OAuth flow (signInWithOAuth) opens the
    // URL via SFSafariViewController, which fails to load on some iOS versions
    // (url_launcher_ios `_failedSafariViewControllerLoadException`). The
    // native flow sidesteps the browser entirely and is the documented
    // Supabase approach for Apple on iOS.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw const supa.AuthException(
          'Apple did not return an identity token.',
        );
      }

      await client.auth.signInWithIdToken(
        provider: supa.OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
        accessToken: credential.authorizationCode,
      );
      return;
    }

    // Web / other platforms: fall back to the browser OAuth flow.
    final redirect = AppConfig.oauthRedirectUri();
    await client.auth.signInWithOAuth(
      supa.OAuthProvider.apple,
      redirectTo: redirect,
    );
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
