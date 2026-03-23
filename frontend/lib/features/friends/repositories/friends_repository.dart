import 'package:dio/dio.dart';

import 'package:frontend/features/expenses/models/expense_list_model.dart';
import 'package:frontend/features/friends/models/friend_balance_model.dart';
import 'package:frontend/features/friends/models/friend_invite_model.dart';
import 'package:frontend/features/friends/models/friend_model.dart';

class FriendsRepository {
  const FriendsRepository(this._dio);

  final Dio _dio;

  Future<List<FriendModel>> fetchFriends() async {
    final response = await _dio.get<dynamic>('/users/friends/');
    final raw = response.data;
    if (raw == null) {
      return [];
    }
    final list = raw as List<dynamic>;
    return list
        .map((e) => FriendModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FriendBalanceModel> fetchFriendBalance(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$userId/balances/',
    );
    return FriendBalanceModel.fromJson(response.data!);
  }

  Future<List<ExpenseListModel>> fetchSharedExpenses(
    String userId, {
    int page = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/expenses/',
      queryParameters: <String, dynamic>{
        'with_user': userId,
        'page': page,
        'limit': 20,
      },
    );
    final data = response.data;
    if (data == null) {
      return [];
    }
    final list = data['data'] as List<dynamic>? ?? const <dynamic>[];
    return list
        .map((e) => ExpenseListModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FriendInviteModel> createInvite() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/users/friends/invite/',
      data: <String, dynamic>{},
    );
    return FriendInviteModel.fromJson(response.data!);
  }

  Future<void> acceptInvite(String token) async {
    await _dio.post<Map<String, dynamic>>(
      '/users/friends/accept/',
      data: <String, dynamic>{'token': token},
    );
  }
}
