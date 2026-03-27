// ignore_for_file: library_private_types_in_public_api

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/profile/repositories/profile_repository.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio mockDio;
  late ProfileRepository repo;

  Map<String, dynamic> userJson({String displayName = 'Alice'}) =>
      <String, dynamic>{
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'email': 'alice@example.com',
        'display_name': displayName,
        'avatar_url': null,
        'phone': null,
        'default_currency': 'BRL',
        'preferred_locale': 'pt_BR',
        'total_owed': '0.00',
        'total_owing': '0.00',
        'net_balance': '0.00',
        'currency': 'BRL',
      };

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    mockDio = _MockDio();
    repo = ProfileRepository(mockDio);
  });

  group('ProfileRepository', () {
    test('updateProfile sends PATCH /users/me/ with display_name', () async {
      when(
        () => mockDio.patch<Map<String, dynamic>>(
          '/users/me/',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: userJson(displayName: 'New Name'),
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/me/'),
        ),
      );

      await repo.updateProfile(<String, dynamic>{'display_name': 'New Name'});

      verify(
        () => mockDio.patch<Map<String, dynamic>>(
          '/users/me/',
          data: <String, dynamic>{'display_name': 'New Name'},
        ),
      ).called(1);
    });

    test('updateProfile returns ProfileModel with updated fields', () async {
      when(
        () => mockDio.patch<Map<String, dynamic>>(
          '/users/me/',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: userJson(displayName: 'Renamed'),
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/me/'),
        ),
      );

      final model = await repo
          .updateProfile(<String, dynamic>{'display_name': 'Renamed'});

      expect(model.displayName, 'Renamed');
    });

    test('deleteAccount sends DELETE /users/me/', () async {
      when(() => mockDio.delete<void>('/users/me/')).thenAnswer(
        (_) async => Response<void>(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/users/me/'),
        ),
      );

      await repo.deleteAccount();

      verify(() => mockDio.delete<void>('/users/me/')).called(1);
    });

    test('fetchAvatarUploadUrl returns upload_url and file_key', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/users/me/avatar-upload-url/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'upload_url': 'https://s3.example/presigned',
            'file_key': 'avatars/u1/photo.jpg',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/me/avatar-upload-url/'),
        ),
      );

      final result =
          await repo.fetchAvatarUploadUrl(contentType: 'image/jpeg');

      expect(result.uploadUrl, 'https://s3.example/presigned');
      expect(result.fileKey, 'avatars/u1/photo.jpg');
      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/users/me/avatar-upload-url/',
          queryParameters: <String, dynamic>{'content_type': 'image/jpeg'},
        ),
      ).called(1);
    });

    test('confirmAvatarUpload sends PATCH /users/me/avatar-confirm/', () async {
      when(
        () => mockDio.patch<Map<String, dynamic>>(
          '/users/me/avatar-confirm/',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{'avatar_url': 'avatars/u1/photo.jpg'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/me/avatar-confirm/'),
        ),
      );
      when(() => mockDio.get<Map<String, dynamic>>('/users/me/')).thenAnswer(
        (_) async {
          final data = userJson(displayName: 'Alice');
          data['avatar_url'] = 'avatars/u1/photo.jpg';
          return Response<Map<String, dynamic>>(
            data: data,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/users/me/'),
          );
        },
      );

      final model = await repo.confirmAvatarUpload('avatars/u1/photo.jpg');

      verify(
        () => mockDio.patch<Map<String, dynamic>>(
          '/users/me/avatar-confirm/',
          data: <String, dynamic>{'file_key': 'avatars/u1/photo.jpg'},
        ),
      ).called(1);
      expect(model.avatarUrl, 'avatars/u1/photo.jpg');
    });

    test('updateProfile maps DioException to ApiException', () async {
      when(
        () => mockDio.patch<Map<String, dynamic>>(
          '/users/me/',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/users/me/'),
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/users/me/'),
            data: 'bad',
          ),
        ),
      );

      expect(
        () => repo.updateProfile(<String, dynamic>{}),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
