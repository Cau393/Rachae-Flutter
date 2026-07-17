import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/network/cert_pinning.dart';
import 'package:frontend/src/config/api_base_url.dart';
import 'package:frontend/src/config/app_config.dart';

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Attaches the Supabase access token and refreshes it when expired (same idea
/// as [SupabaseClient] internal `_getAccessToken`, which Dio bypasses).
class SupabaseTokenInterceptor extends QueuedInterceptor {
  SupabaseTokenInterceptor(this._client);

  final SupabaseClient _client;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _prepareRequest(options, handler);
  }

  Future<void> _prepareRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final session = _client.auth.currentSession;
      final wasExpired = session != null && session.isExpired;
      if (wasExpired) {
        try {
          await _client.auth.refreshSession();
        } catch (_) {
          // Refresh failures fall through; request proceeds with the (now
          // stale) token and the server returns 401, which upstream handles.
        }
      }
      final token = _client.auth.currentSession?.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } finally {
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 400) {
      final message =
          err.response?.data?.toString() ?? err.message ?? 'Unknown error';
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: ApiException(statusCode: statusCode, message: message),
          response: err.response,
          type: err.type,
        ),
      );
      return;
    }
    handler.next(err);
  }
}

class ApiClient {
  ApiClient({SupabaseClient? supabaseClient}) {
    final client = supabaseClient ?? Supabase.instance.client;
    final baseUrl = _resolveApiBaseUrl();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (baseUrl.contains('ngrok-free.dev') || baseUrl.contains('ngrok.io')) {
      // ngrok free tier returns an HTML interstitial unless this header is set.
      headers['ngrok-skip-browser-warning'] = 'true';
    }
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // Dev/slow networks often exceed 10s (e.g. cold Django, debugger); avoid false timeouts.
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: headers,
      ),
    );
    // Disabled by default — see `cert_pinning.dart` for why and the
    // rotation plan required before enabling in production.
    configureCertPinning(dio);
    dio.interceptors.add(SupabaseTokenInterceptor(client));
  }

  late final Dio dio;
}

String _resolveApiBaseUrl() {
  const defined = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  return resolveApiBaseUrlForTesting(
    isReleaseMode: kReleaseMode,
    isWeb: kIsWeb,
    definedValue: defined,
  );
}

/// Extracted so the release-web guard is unit-testable: `kReleaseMode` is
/// always `false` under `flutter test`, so [_resolveApiBaseUrl] alone can
/// never exercise the throw path. Production callers should go through
/// [_resolveApiBaseUrl]; this stays behaviorally identical for them.
bool _isNgrokUrl(String url) =>
    url.contains('ngrok-free.dev') || url.contains('ngrok.io');

@visibleForTesting
String resolveApiBaseUrlForTesting({
  required bool isReleaseMode,
  required bool isWeb,
  String definedValue = '',
}) {
  if (definedValue.isNotEmpty) {
    // Dev tunnels must never ship: a release build pointed at an ngrok URL
    // means the API_BASE_URL wasn't actually configured for production.
    if (isReleaseMode && _isNgrokUrl(definedValue)) {
      throw StateError(
        'API_BASE_URL="$definedValue" looks like an ngrok dev tunnel, which '
        'must never be used in a release build. Use the production URL '
        '(see `frontend/env/prod.json`) via `--dart-define-from-file`.',
      );
    }
    return definedValue;
  }
  // The web shim (`api_base_url_html.dart`) derives a URL from
  // `window.location`, which is silently wrong for hosts (e.g. Vercel) that
  // don't serve the API on the same origin — it must never win in a release
  // web build.
  if (isReleaseMode && isWeb) {
    throw StateError(
      'API_BASE_URL must be provided via --dart-define for release web '
      'builds. Build with `flutter build web --release '
      '--dart-define=API_BASE_URL=<url>`.',
    );
  }
  if (isWeb) {
    final fromWindow = webApiBaseUrl();
    if (fromWindow.isNotEmpty) {
      return fromWindow;
    }
  }
  // Fallback to `dotenv` on native (loaded from repo `.env` when cwd is the
  // repo, e.g. desktop / tests). Physical iOS/Android devices can't read the
  // repo `.env` — use `--dart-define-from-file=../.env` instead.
  try {
    if (!isWeb && dotenv.isInitialized) {
      final v = dotenv.maybeGet('API_BASE_URL')?.trim();
      if (v != null && v.isNotEmpty) {
        if (isReleaseMode && _isNgrokUrl(v)) {
          throw StateError(
            'API_BASE_URL="$v" (from .env) looks like an ngrok dev tunnel, '
            'which must never be used in a release build. Use the '
            'production URL (see `frontend/env/prod.json`) via '
            '`--dart-define-from-file`.',
          );
        }
        return v;
      }
    }
  } on StateError {
    rethrow;
  } catch (_) {
    // dotenv not initialized on this platform; fall through.
  }
  // Release native (iOS/Android) with no dart-define and no dotenv value:
  // fall back to the production backend instead of `localhost`, which would
  // silently ship a build that can never reach the API. See
  // `frontend/env/prod.json` for how to set API_BASE_URL explicitly via
  // `--dart-define-from-file`.
  if (isReleaseMode && !isWeb) {
    return AppConfig.productionApiBaseUrl;
  }
  // Debug-only warning: `localhost` on a physical device points at the device
  // itself, so nothing the Mac serves is reachable. See README dev setup.
  if (kDebugMode && !isWeb) {
    debugPrint(
      '[ApiClient] No API_BASE_URL provided; falling back to '
      'http://localhost:8000/api/v1/. On a physical device this WILL fail '
      'with "Connection refused" because localhost points at the device. '
      'Run with `flutter run --dart-define-from-file=../.env` (and set '
      '`API_BASE_URL=http://<mac-lan-ip>:8000/api/v1/` in repo `.env`).',
    );
  }
  return 'http://localhost:8000/api/v1/';
}
