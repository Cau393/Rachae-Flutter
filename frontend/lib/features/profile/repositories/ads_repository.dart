import 'package:dio/dio.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/profile/models/ads_status_model.dart';

class AdsRepository {
  const AdsRepository(this._dio);

  final Dio _dio;

  Future<AdsStatusModel> fetchAdsStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/ads/status/');
      final data = response.data;
      if (data == null) {
        throw const ApiException(statusCode: 0, message: 'Empty response');
      }
      return AdsStatusModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioToApi(e);
    }
  }

  Future<String> createCheckoutSession({required String plan}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/ads/create-checkout-session/',
        data: <String, dynamic>{'plan': plan},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(statusCode: 0, message: 'Empty response');
      }
      final inner = data['data'] as Map<String, dynamic>;
      return inner['checkout_url'] as String;
    } on DioException catch (e) {
      throw _mapDioToApi(e);
    }
  }

  Future<String> createPortalSession() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/ads/create-portal-session/',
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(statusCode: 0, message: 'Empty response');
      }
      final inner = data['data'] as Map<String, dynamic>;
      return inner['portal_url'] as String;
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
