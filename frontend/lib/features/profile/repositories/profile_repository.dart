import 'package:dio/dio.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/profile/models/profile_model.dart';

class ProfileRepository {
  const ProfileRepository(this._dio);

  final Dio _dio;

  Future<ProfileModel> fetchProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me/');
      final data = response.data;
      if (data == null) {
        throw const ApiException(statusCode: 0, message: 'Empty response');
      }
      return ProfileModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioToApi(e);
    }
  }

  Future<ProfileModel> updateProfile(Map<String, dynamic> fields) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/users/me/',
        data: fields,
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(statusCode: 0, message: 'Empty response');
      }
      return ProfileModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioToApi(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _dio.delete<void>('/users/me/');
    } on DioException catch (e) {
      throw _mapDioToApi(e);
    }
  }

  Future<({String uploadUrl, String fileKey})> fetchAvatarUploadUrl({
    String contentType = 'image/jpeg',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/me/avatar-upload-url/',
        queryParameters: <String, dynamic>{'content_type': contentType},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(statusCode: 0, message: 'Empty response');
      }
      return (
        uploadUrl: data['upload_url'] as String,
        fileKey: data['file_key'] as String,
      );
    } on DioException catch (e) {
      throw _mapDioToApi(e);
    }
  }

  /// Backend PATCH returns only `avatar_url`; we reload the full profile.
  Future<ProfileModel> confirmAvatarUpload(String fileKey) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/users/me/avatar-confirm/',
        data: <String, dynamic>{'file_key': fileKey},
      );
      return fetchProfile();
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
