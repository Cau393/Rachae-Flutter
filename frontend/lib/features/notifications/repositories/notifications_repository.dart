import 'package:dio/dio.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/notifications/models/notification_preference_model.dart';

class NotificationsRepository {
  const NotificationsRepository(this._dio);

  final Dio _dio;

  Future<NotificationPreferenceModel> fetchPreferences() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/notifications/preferences/');
      final data = response.data;
      if (data == null) {
        throw const ApiException(statusCode: 0, message: 'Empty response');
      }
      final inner = data['data'] as Map<String, dynamic>;
      return NotificationPreferenceModel.fromJson(inner);
    } on DioException catch (e) {
      throw _mapDioToApi(e);
    }
  }

  /// PATCH partial update (backend field names as keys).
  Future<void> updatePreferences(Map<String, dynamic> fields) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/notifications/preferences/',
        data: fields,
      );
    } on DioException catch (e) {
      throw _mapDioToApi(e);
    }
  }

  ApiException _mapDioToApi(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final message =
        e.response?.data?.toString() ?? e.message ?? 'Unknown error';
    return ApiException(statusCode: status, message: message);
  }
}
