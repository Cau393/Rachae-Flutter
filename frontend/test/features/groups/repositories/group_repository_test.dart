// ignore_for_file: library_private_types_in_public_api

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/groups/models/group_balance_model.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';
import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/models/settlement_suggestion_model.dart';
import 'package:frontend/features/groups/repositories/group_repository.dart';

class _MockDio extends Mock implements Dio {}

late _MockDio mockDio;
late GroupRepository repo;

const _groupId = '11111111-1111-1111-1111-111111111111';
const _createdAt = '2025-03-01T08:00:00.000Z';

Map<String, dynamic> _detailMap() => {
      'id': _groupId,
      'name': 'Home group',
      'description': 'Shared flat',
      'type': 'home',
      'currency': 'BRL',
      'simplify_debts': true,
      'created_by': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'members': <dynamic>[
        {
          'user_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'display_name': 'Ada',
          'avatar_url': null,
          'role': 'ADMIN',
          'joined_at': '2025-03-01T09:00:00.000Z',
          'invited_by': null,
        },
      ],
      'net_balances': <dynamic>[
        {
          'user_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'display_name': 'Ada',
          'net_balance': '10.00',
        },
      ],
      'created_at': _createdAt,
    };

Map<String, dynamic> _summaryItem(String id, String name) => {
      'id': id,
      'name': name,
      'type': 'trip',
      'currency': 'BRL',
      'member_count': 3,
      'your_net_balance': '-5.00',
      'created_at': _createdAt,
    };

bool _dioHasApiError(Object e, int statusCode) {
  if (e is! DioException) return false;
  final err = e.error;
  return err is ApiException && err.statusCode == statusCode;
}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    mockDio = _MockDio();
    repo = GroupRepository(mockDio);
  });

  group('fetchGroups', () {
    test('calls GET /groups/ with no query parameters and parses two items',
        () async {
      when(
        () => mockDio.get<dynamic>(
          '/groups/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: [
            _summaryItem(
              '22222222-2222-2222-2222-222222222222',
              'A',
            ),
            _summaryItem(
              '33333333-3333-3333-3333-333333333333',
              'B',
            ),
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/groups/'),
        ),
      );

      final result = await repo.fetchGroups();
      expect(result, hasLength(2));
      expect(result[0], isA<GroupSummaryModel>());
      expect(result[0].id, '22222222-2222-2222-2222-222222222222');
      expect(result[1].name, 'B');

      verify(
        () => mockDio.get<dynamic>(
          '/groups/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });

    test(
      'propagates DioException with nested ApiException on 403',
      () async {
        when(
          () => mockDio.get<dynamic>(
            '/groups/',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/groups/'),
            response: Response<void>(
              statusCode: 403,
              requestOptions: RequestOptions(path: '/groups/'),
            ),
            type: DioExceptionType.badResponse,
            error: const ApiException(statusCode: 403, message: 'forbidden'),
          ),
        );

        await expectLater(
          repo.fetchGroups(),
          throwsA(predicate((Object e) => _dioHasApiError(e, 403))),
        );
      },
    );
  });

  group('fetchGroupDetail', () {
    test('calls GET /groups/{id}/ and returns GroupDetailModel', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/groups/$_groupId/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: _detailMap(),
          statusCode: 200,
          requestOptions: RequestOptions(path: '/groups/$_groupId/'),
        ),
      );

      final result = await repo.fetchGroupDetail(_groupId);
      expect(result, isA<GroupDetailModel>());
      expect(result.id, _groupId);
      expect(result.members, hasLength(1));

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/groups/$_groupId/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });

  group('fetchGroupMembers', () {
    test('calls GET /groups/{id}/members/ and parses list', () async {
      when(
        () => mockDio.get<dynamic>(
          '/groups/$_groupId/members/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: [
            {
              'user_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
              'display_name': 'Ada',
              'avatar_url': null,
              'role': 'ADMIN',
              'joined_at': '2025-03-01T09:00:00.000Z',
              'invited_by': null,
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/groups/$_groupId/members/'),
        ),
      );

      final result = await repo.fetchGroupMembers(_groupId);
      expect(result, hasLength(1));
      expect(result.first, isA<GroupMemberModel>());
      expect(result.first.role, 'ADMIN');
    });
  });

  group('fetchGroupBalances', () {
    test('returns record with balances and currency', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/groups/$_groupId/balances/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'group_id': _groupId,
            'currency': 'BRL',
            'balances': [
              {
                'user_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
                'display_name': 'Ada',
                'net_balance': '10.00',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/groups/$_groupId/balances/'),
        ),
      );

      final result = await repo.fetchGroupBalances(_groupId);
      expect(result.currency, 'BRL');
      expect(result.balances, hasLength(1));
      expect(result.balances.first, isA<GroupBalanceModel>());
      expect(result.balances.first.netBalance, '10.00');
    });
  });

  group('fetchSimplifiedBalances', () {
    test('merges top-level currency into each suggestion', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/groups/$_groupId/balances/simplified/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'group_id': _groupId,
            'currency': 'BRL',
            'simplify_debts': true,
            'suggestions': [
              {
                'payer_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
                'payer_name': 'Bob',
                'receiver_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
                'receiver_name': 'Ada',
                'amount': '15.00',
              },
            ],
          },
          statusCode: 200,
          requestOptions:
              RequestOptions(path: '/groups/$_groupId/balances/simplified/'),
        ),
      );

      final result = await repo.fetchSimplifiedBalances(_groupId);
      expect(result.simplifyDebts, isTrue);
      expect(result.suggestions, hasLength(1));
      expect(result.suggestions.first, isA<SettlementSuggestionModel>());
      expect(result.suggestions.first.currency, 'BRL');
      expect(result.suggestions.first.amount, '15.00');
    });

    test('handles simplify_debts false with empty suggestions', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/groups/$_groupId/balances/simplified/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'group_id': _groupId,
            'currency': 'BRL',
            'simplify_debts': false,
            'suggestions': <dynamic>[],
          },
          statusCode: 200,
          requestOptions:
              RequestOptions(path: '/groups/$_groupId/balances/simplified/'),
        ),
      );

      final result = await repo.fetchSimplifiedBalances(_groupId);
      expect(result.simplifyDebts, isFalse);
      expect(result.suggestions, isEmpty);
    });
  });

  group('createGroup', () {
    test('sends POST /groups/ with body and returns GroupDetailModel on 201',
        () async {
      final body = <String, dynamic>{
        'name': 'New',
        'description': null,
        'type': 'other',
        'currency': 'BRL',
        'simplify_debts': true,
        'member_ids': <String>[],
      };
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/groups/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: _detailMap(),
          statusCode: 201,
          requestOptions: RequestOptions(path: '/groups/'),
        ),
      );

      final result = await repo.createGroup(body);
      expect(result, isA<GroupDetailModel>());
      expect(result.id, _groupId);

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/groups/',
          data: body,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });

  group('updateGroup', () {
    test(
      'propagates DioException with nested ApiException on 400',
      () async {
        when(
          () => mockDio.patch<Map<String, dynamic>>(
            '/groups/$_groupId/',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/groups/$_groupId/'),
            response: Response<void>(
              statusCode: 400,
              requestOptions: RequestOptions(path: '/groups/$_groupId/'),
            ),
            type: DioExceptionType.badResponse,
            error: const ApiException(statusCode: 400, message: 'bad'),
          ),
        );

        await expectLater(
          repo.updateGroup(_groupId, {'currency': 'USD'}),
          throwsA(predicate((Object e) => _dioHasApiError(e, 400))),
        );
      },
    );
  });

  group('deleteGroup', () {
    test('calls DELETE /groups/{id}/ and completes on 204', () async {
      when(
        () => mockDio.delete<void>(
          '/groups/$_groupId/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/groups/$_groupId/'),
        ),
      );

      await repo.deleteGroup(_groupId);

      verify(
        () => mockDio.delete<void>(
          '/groups/$_groupId/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });

  group('addMember', () {
    test(
      'sends POST /groups/{id}/members/ with user_id and role',
      () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            '/groups/$_groupId/members/',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: {
              'user_id': 'u1',
              'display_name': 'U',
              'avatar_url': null,
              'role': 'MEMBER',
              'joined_at': _createdAt,
              'invited_by': null,
            },
            statusCode: 201,
            requestOptions: RequestOptions(path: '/groups/$_groupId/members/'),
          ),
        );

        final result = await repo.addMember(_groupId, 'u1', 'MEMBER');
        expect(result.userId, 'u1');
        expect(result.role, 'MEMBER');

        verify(
          () => mockDio.post<Map<String, dynamic>>(
            '/groups/$_groupId/members/',
            data: <String, dynamic>{'user_id': 'u1', 'role': 'MEMBER'},
            queryParameters: any(named: 'queryParameters'),
          ),
        ).called(1);
      },
    );
  });

  group('changeMemberRole', () {
    test('calls PATCH /groups/{id}/members/{userId}/ with role body', () async {
      const userId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
      when(
        () => mockDio.patch<Map<String, dynamic>>(
          '/groups/$_groupId/members/$userId/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'user_id': userId,
            'display_name': 'Bob',
            'avatar_url': null,
            'role': 'ADMIN',
            'joined_at': _createdAt,
            'invited_by': null,
          },
          statusCode: 200,
          requestOptions:
              RequestOptions(path: '/groups/$_groupId/members/$userId/'),
        ),
      );

      final result = await repo.changeMemberRole(_groupId, userId, 'ADMIN');
      expect(result.isAdmin, isTrue);

      verify(
        () => mockDio.patch<Map<String, dynamic>>(
          '/groups/$_groupId/members/$userId/',
          data: <String, dynamic>{'role': 'ADMIN'},
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });

  group('removeMember', () {
    test('calls DELETE /groups/{id}/members/{userId}/ on 204', () async {
      const userId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
      when(
        () => mockDio.delete<void>(
          '/groups/$_groupId/members/$userId/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          statusCode: 204,
          requestOptions:
              RequestOptions(path: '/groups/$_groupId/members/$userId/'),
        ),
      );

      await repo.removeMember(_groupId, userId);

      verify(
        () => mockDio.delete<void>(
          '/groups/$_groupId/members/$userId/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });

  group('leaveGroup', () {
    test('calls POST /groups/{id}/leave/', () async {
      when(
        () => mockDio.post<void>(
          '/groups/$_groupId/leave/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/groups/$_groupId/leave/'),
        ),
      );

      await repo.leaveGroup(_groupId);

      verify(
        () => mockDio.post<void>(
          '/groups/$_groupId/leave/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });
}
