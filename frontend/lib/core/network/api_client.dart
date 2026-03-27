import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        } catch (_) {}
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
  if (defined.isNotEmpty) {
    return defined;
  }
  if (kIsWeb) {
    final fromWindow = webApiBaseUrl();
    if (fromWindow.isNotEmpty) {
      return fromWindow;
    }
  }
  return 'http://localhost:8000/api/v1/';
}
