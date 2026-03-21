import 'dart:async' show unawaited;

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// #region agent log
void _agentIngestLog({
  required String hypothesisId,
  required String location,
  required String message,
  required Map<String, dynamic> data,
  String runId = 'pre-fix',
}) {
  unawaited(() async {
    try {
      final body = <String, dynamic>{
        'sessionId': '5c3a4e',
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      ).post(
        'http://127.0.0.1:7668/ingest/68a38bd1-100a-4607-82bb-151155a5a3b4',
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': '5c3a4e',
          },
        ),
      );
    } catch (_) {}
  }());
}
// #endregion

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
      // #region agent log
      final fullPath = '${options.baseUrl}${options.path}'.toLowerCase();
      final logGroupPost =
          options.method.toUpperCase() == 'POST' && fullPath.contains('group');
      if (logGroupPost) {
        _agentIngestLog(
          hypothesisId: 'H1,H4',
          location: 'api_client.dart:SupabaseTokenInterceptor.onRequest',
          message: 'group_post_auth_state',
          data: <String, dynamic>{
            'path': options.path,
            'hasAccessToken': token != null && token.isNotEmpty,
            'tokenLength': token?.length ?? 0,
            'attemptedRefreshForExpiry': wasExpired,
          },
        );
      }
      // #endregion
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
    // #region agent log
    if (statusCode == 401) {
      final auth = err.requestOptions.headers['Authorization'];
      final hadAuth =
          auth != null && auth.toString().trim().isNotEmpty;
      _agentIngestLog(
        hypothesisId: 'H1,H2,H3',
        location: 'api_client.dart:SupabaseTokenInterceptor.onError',
        message: 'http_401',
        data: <String, dynamic>{
          'path': err.requestOptions.path,
          'hadAuthorizationHeader': hadAuth,
        },
      );
    }
    // #endregion
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
    dio = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:8000/api/v1/',
        ),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(SupabaseTokenInterceptor(client));
  }

  late final Dio dio;
}
