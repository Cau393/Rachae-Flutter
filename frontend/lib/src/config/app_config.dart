import 'package:flutter/foundation.dart';

import 'oauth_redirect_uri.dart';

class AppConfig {
  static const supabaseUrl = 'https://tjjaojtwsmnwmxfqorse.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqamFvanR3c21ud214ZnFvcnNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE3ODQ0ODksImV4cCI6MjA4NzM2MDQ4OX0.Mis0vMAB7rweGnW2hyhJgjT5A-FvygtXQjku80lay3g';
  static const iosRedirectUrl = 'io.supabase.rachae://login-callback';

  /// Supabase OAuth [redirectTo]. Must match an entry in the Supabase project
  /// **Authentication → URL Configuration → Redirect URLs** (e.g. wildcard
  /// `http://localhost:**` for local web, plus [iosRedirectUrl] for native).
  ///
  /// On **web**, `redirectTo: null` uses the dashboard **Site URL** (often
  /// `http://localhost:3000`). [Uri.base] can also differ from the real address
  /// bar (LAN IP, port), so Supabase rejects `redirect_to` and falls back to
  /// Site URL — use [window.location] via [webOAuthRedirectUri] instead.
  static String oauthRedirectUri() {
    if (kIsWeb) {
      final fromWindow = webOAuthRedirectUri();
      if (fromWindow.isNotEmpty) {
        return fromWindow;
      }
      final b = Uri.base;
      if (b.scheme == 'http' || b.scheme == 'https') {
        final noFragment = b.hasFragment ? b.replace(fragment: '') : b;
        return noFragment.toString();
      }
    }
    return iosRedirectUrl;
  }

  /// Production backend URL (Railway). Used as the release-mode, native
  /// (non-web) fallback in [resolveApiBaseUrlForTesting] when no
  /// `API_BASE_URL` dart-define or dotenv value is provided, so a release
  /// build never silently falls back to `localhost`. See
  /// `frontend/env/prod.json` for `--dart-define-from-file` usage.
  static const productionApiBaseUrl =
      'https://rachae-flutter-production-11b3.up.railway.app/api/v1/';

  /// Public app listing URLs (optional overrides via `--dart-define`).
  static const iosAppStoreListingUrl = String.fromEnvironment(
    'IOS_APP_STORE_URL',
    defaultValue: 'https://apps.apple.com/',
  );
  static const androidPlayStoreListingUrl = String.fromEnvironment(
    'ANDROID_PLAY_STORE_URL',
    defaultValue: 'https://play.google.com/',
  );
}
