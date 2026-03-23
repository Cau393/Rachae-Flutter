import 'package:flutter/foundation.dart';

@immutable
class FriendInviteModel {
  const FriendInviteModel({
    required this.id,
    this.email,
    this.phone,
    required this.token,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.inviteUrl,
  });

  final String id;
  final String? email;
  final String? phone;
  final String token;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String inviteUrl;

  factory FriendInviteModel.fromJson(Map<String, dynamic> json) {
    return FriendInviteModel(
      id: json['id'].toString(),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      token: json['token'] as String,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      inviteUrl: json['invite_url'] as String,
    );
  }
}
