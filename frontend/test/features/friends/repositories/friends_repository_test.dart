import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/friends/models/friend_balance_model.dart';
import 'package:frontend/features/friends/models/friend_invite_model.dart';
import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/repositories/friends_repository.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';

class MockDio extends Mock implements Dio {}

late MockDio mockDio;
late FriendsRepository repo;

const _friendId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const _createdAt = '2024-02-01T10:00:00.000Z';

Map<String, dynamic> _paidBy() => <String, dynamic>{
      'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      'display_name': 'Payer',
      'avatar_url': null,
    };

Map<String, dynamic> expenseListItemJson(String id) => <String, dynamic>{
      'id': id,
      'group_id': '660e8400-e29b-41d4-a716-446655440002',
      'paid_by': _paidBy(),
      'amount': '50.00',
      'currency': 'BRL',
      'amount_in_group_currency': '50.00',
      'description': 'Shared',
      'category': 'geral',
      'expense_date': '2024-01-15',
      'split_method': 'equal',
      'split_count': 2,
      'is_deleted': false,
      'created_at': _createdAt,
    };

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    mockDio = MockDio();
    repo = FriendsRepository(mockDio);
  });

  group('fetchFriends', () {
    test('calls GET /users/friends/ with no query params and parses a list',
        () async {
      when(
        () => mockDio.get<dynamic>(
          '/users/friends/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: <dynamic>[
            <String, dynamic>{
              'id': _friendId,
              'display_name': 'Alice',
              'email': 'alice@example.com',
              'phone': null,
              'avatar_url': null,
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/friends/'),
        ),
      );

      final result = await repo.fetchFriends();
      expect(result, hasLength(1));
      expect(result.first, isA<FriendModel>());
      expect(result.first.id, _friendId);
      expect(result.first.displayName, 'Alice');

      verify(
        () => mockDio.get<dynamic>(
          '/users/friends/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });

  group('fetchFriendBalance', () {
    test('calls GET /users/{id}/balances/ and returns FriendBalanceModel',
        () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/users/$_friendId/balances/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'balance': '12.50',
            'currency': 'BRL',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/$_friendId/balances/'),
        ),
      );

      final result = await repo.fetchFriendBalance(_friendId);
      expect(result, isA<FriendBalanceModel>());
      expect(result.balance, '12.50');
      expect(result.currency, 'BRL');

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/users/$_friendId/balances/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });

  group('fetchSharedExpenses', () {
    test('includes with_user, page, and limit query params', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/expenses/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'data': [expenseListItemJson('11111111-1111-1111-1111-111111111111')],
            'pagination': <String, dynamic>{
              'count': 1,
              'next': null,
              'previous': null,
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/expenses/'),
        ),
      );

      final result = await repo.fetchSharedExpenses(_friendId, page: 2);
      expect(result, hasLength(1));
      expect(result.first, isA<ExpenseListModel>());

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/expenses/',
          queryParameters: <String, dynamic>{
            'with_user': _friendId,
            'page': 2,
            'limit': 20,
          },
        ),
      ).called(1);
    });
  });

  group('createInvite', () {
    test('posts an empty JSON object and parses open-link response', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/users/friends/invite/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'id': 'cccccccc-cccc-cccc-cccc-cccccccccccc',
            'email': null,
            'phone': null,
            'token': 'tok',
            'status': 'PENDING',
            'expires_at': '2026-12-31T23:59:59Z',
            'created_at': '2026-01-01T12:00:00Z',
            'invite_url': 'https://app.example/invite?token=tok',
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/users/friends/invite/'),
        ),
      );

      final result = await repo.createInvite();
      expect(result, isA<FriendInviteModel>());
      expect(result.phone, isNull);

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/users/friends/invite/',
          data: <String, dynamic>{},
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });

  group('acceptInvite', () {
    test('posts token to /users/friends/accept/', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/users/friends/accept/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'id': 'ffffffff-ffff-ffff-ffff-ffffffffffff',
            'email': 'invitee@example.com',
            'phone': '+5511999999999',
            'token': 'accept-token',
            'status': 'accepted',
            'expires_at': '2026-12-31T23:59:59Z',
            'created_at': '2026-01-01T12:00:00Z',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/friends/accept/'),
        ),
      );

      await repo.acceptInvite('accept-token');
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/users/friends/accept/',
          data: <String, dynamic>{'token': 'accept-token'},
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });
}
