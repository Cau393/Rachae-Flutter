import 'package:dio/dio.dart';

import 'package:frontend/features/groups/models/group_balance_model.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';
import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/models/settlement_suggestion_model.dart';

class GroupRepository {
  const GroupRepository(this._dio);

  final Dio _dio;

  Future<List<GroupSummaryModel>> fetchGroups() async {
    final response = await _dio.get<dynamic>('/groups/');
    final list = response.data! as List<dynamic>;
    return GroupSummaryModel.fromJsonList(list);
  }

  Future<GroupDetailModel> fetchGroupDetail(String groupId) async {
    final response = await _dio.get<Map<String, dynamic>>('/groups/$groupId/');
    return GroupDetailModel.fromJson(response.data!);
  }

  Future<List<GroupMemberModel>> fetchGroupMembers(String groupId) async {
    final response = await _dio.get<dynamic>('/groups/$groupId/members/');
    final list = response.data! as List<dynamic>;
    return list
        .map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({List<GroupBalanceModel> balances, String currency})>
      fetchGroupBalances(String groupId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/groups/$groupId/balances/');
    final data = response.data!;
    final raw = data['balances'] as List<dynamic>;
    final currency = data['currency'] as String;
    final balances = raw
        .map((e) => GroupBalanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (balances: balances, currency: currency);
  }

  Future<({bool simplifyDebts, List<SettlementSuggestionModel> suggestions})>
      fetchSimplifiedBalances(String groupId) async {
    final response = await _dio
        .get<Map<String, dynamic>>('/groups/$groupId/balances/simplified/');
    final data = response.data!;
    final simplifyDebts = data['simplify_debts'] as bool;
    final currency = data['currency'] as String;
    final raw = data['suggestions'] as List<dynamic>? ?? const <dynamic>[];
    final suggestions = raw.map((e) {
      final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
      map['currency'] = currency;
      return SettlementSuggestionModel.fromJson(map);
    }).toList();
    return (simplifyDebts: simplifyDebts, suggestions: suggestions);
  }

  Future<GroupDetailModel> createGroup(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/',
      data: body,
    );
    return GroupDetailModel.fromJson(response.data!);
  }

  Future<GroupDetailModel> updateGroup(
    String groupId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/groups/$groupId/',
      data: body,
    );
    return GroupDetailModel.fromJson(response.data!);
  }

  Future<void> deleteGroup(String groupId) async {
    await _dio.delete<void>('/groups/$groupId/');
  }

  Future<GroupMemberModel> addMember(
    String groupId,
    String userId,
    String role,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/members/',
      data: <String, dynamic>{'user_id': userId, 'role': role},
    );
    return GroupMemberModel.fromJson(response.data!);
  }

  Future<GroupMemberModel> changeMemberRole(
    String groupId,
    String userId,
    String role,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/groups/$groupId/members/$userId/',
      data: <String, dynamic>{'role': role},
    );
    return GroupMemberModel.fromJson(response.data!);
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _dio.delete<void>('/groups/$groupId/members/$userId/');
  }

  Future<void> leaveGroup(String groupId) async {
    await _dio.post<void>('/groups/$groupId/leave/');
  }
}
