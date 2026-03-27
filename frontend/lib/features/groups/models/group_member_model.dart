import 'package:flutter/foundation.dart';

@immutable
class GroupMemberModel {
  const GroupMemberModel({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.role,
    required this.joinedAt,
    required this.invitedBy,
  });

  /// Django user id; same identifier as a friend’s `id` when adding to a group.
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;
  final String? invitedBy;

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['user_id'].toString(),
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      invitedBy: json['invited_by']?.toString(),
    );
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isMember => role == 'MEMBER';
  bool get isViewer => role == 'VIEWER';
}
