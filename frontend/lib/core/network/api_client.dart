import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/src/config/api_base_url.dart';

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
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // Dev/slow networks often exceed 10s (e.g. cold Django, debugger); avoid false timeouts.
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
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
@visibleForTesting
String resolveApiBaseUrlForTesting({
  required bool isReleaseMode,
  required bool isWeb,
  String definedValue = '',
}) {
  if (definedValue.isNotEmpty) {
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
        return v;
      }
    }
  } catch (_) {
    // dotenv not initialized on this platform; fall through.
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
