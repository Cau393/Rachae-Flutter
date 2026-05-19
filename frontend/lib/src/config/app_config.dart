import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  // Local dev: flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1/
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-backend.railway.app/api/v1/',
  );

  /// RevenueCat public SDK key (Apple / iOS).
  ///
  /// **Physical device / simulator:** repo `../.env` is on the Mac, not on the
  /// device, so [loadRepoDotenv] usually cannot read `REVENUECAT_IOS_API_KEY`
  /// there. Use either:
  /// - `flutter run --dart-define-from-file=../.env` (from `frontend/`), or
  /// - `flutter run --dart-define=REVENUECAT_IOS_API_KEY=your_public_sdk_key`
  ///
  /// **Desktop / tests** when the process cwd is `frontend/`, [loadRepoDotenv]
  /// may load repo-root `.env` into [dotenv] as a fallback.
  static String get revenueCatIosApiKey {
    const fromDefine = String.fromEnvironment(
      'REVENUECAT_IOS_API_KEY',
      defaultValue: '',
    );
    final trimmedDefine = fromDefine.trim();
    if (trimmedDefine.isNotEmpty) {
      return trimmedDefine;
    }
    try {
      if (dotenv.isInitialized) {
        final v = dotenv.maybeGet('REVENUECAT_IOS_API_KEY')?.trim();
        if (v != null && v.isNotEmpty) {
          return v;
        }
      }
    } catch (_) {
      // dotenv not loaded or not initialized
    }
    return '';
  }

  /// Public app listing URLs (optional overrides via `--dart-define`).
  static const iosAppStoreListingUrl = String.fromEnvironment(
    'IOS_APP_STORE_URL',
    defaultValue: 'https://apps.apple.com/',
  );
  static const androidPlayStoreListingUrl = String.fromEnvironment(
    'ANDROID_PLAY_STORE_URL',
    defaultValue: 'https://play.google.com/',
  );

  /// AdSense publisher id (`ca-pub-…`). Override via `--dart-define=AD_SENSE_CLIENT=…`.
  /// Must match the `client` query on `adsbygoogle.js` in [web/index.html] for releases.
  static const adSenseClient = String.fromEnvironment(
    'AD_SENSE_CLIENT',
    defaultValue: 'ca-pub-7543427210522470',
  );

  /// AdSense display unit slot id. `--dart-define=AD_SENSE_SLOT=…`
  static const adSenseSlot = String.fromEnvironment(
    'AD_SENSE_SLOT',
    defaultValue: '1298705263',
  );

  /// Reserved strip height for the responsive AdSense unit on web.
  static const double adSenseBannerHeight = 100;
}
