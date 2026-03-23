import 'package:flutter/foundation.dart';

@immutable
class FriendModel {
  const FriendModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String email;
  final String? phone;
  final String? avatarUrl;

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'].toString(),
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed[0].toUpperCase();
  }

  @override
  bool operator ==(Object other) => other is FriendModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
