import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase session (including the long-lived refresh token) in
/// the platform Keychain (iOS) / Keystore (Android) instead of the default
/// `SharedPreferencesLocalStorage`, which writes to unencrypted
/// NSUserDefaults/SharedPreferences — recoverable from an unencrypted device
/// backup or a jailbroken/rooted device. See `.claude/rules/security.md`:
/// "Store auth tokens and PII in flutter_secure_storage, never
/// SharedPreferences."
///
/// Native (non-web) only. On web, [main] passes `EmptyLocalStorage` instead
/// (`flutter_secure_storage`'s web backend is `window.localStorage` under the
/// hood, so it would not improve on the default there).
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'supabase.session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _sessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);
}
