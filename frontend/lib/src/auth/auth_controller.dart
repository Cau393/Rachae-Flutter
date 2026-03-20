import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authControllerProvider = Provider<AuthController>((ref) {
  final controller = AuthController(ref.watch(supabaseClientProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

class AuthController extends ChangeNotifier {
  AuthController(this._client) {
    _subscription = _client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _subscription;

  Session? get session => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => session != null;
  bool get isSupportedPlatform =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : AppConfig.iosRedirectUrl,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      queryParams: const {
        'prompt': 'select_account',
      },
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut(scope: SignOutScope.global);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
