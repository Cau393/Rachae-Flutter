import 'package:flutter/foundation.dart';
import 'package:frontend/features/groups/models/group_balance_model.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';

@immutable
class GroupDetailModel {
  const GroupDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.currency,
    required this.simplifyDebts,
    required this.createdBy,
    required this.members,
    required this.netBalances,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final String type;
  final String currency;
  final bool simplifyDebts;
  final String createdBy;
  final List<GroupMemberModel> members;
  final List<GroupBalanceModel> netBalances;
  final DateTime createdAt;

  factory GroupDetailModel.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List<dynamic>? ?? const <dynamic>[];
    final balancesJson =
        json['net_balances'] as List<dynamic>? ?? const <dynamic>[];
    return GroupDetailModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      currency: json['currency'] as String,
      simplifyDebts: json['simplify_debts'] as bool,
      createdBy: json['created_by'].toString(),
      members: membersJson
          .map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      netBalances: balancesJson
          .map((e) => GroupBalanceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  GroupMemberModel? memberByUserId(String id) {
    for (final m in members) {
      if (m.userId == id) return m;
    }
    return null;
  }
}
