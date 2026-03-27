import 'package:flutter/foundation.dart';

@immutable
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.phone,
    required this.defaultCurrency,
    required this.preferredLocale,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? phone;
  final String defaultCurrency;
  final String preferredLocale;

  /// Local part of [email] (before `@`), trimmed. If there is no `@`, returns the
  /// whole trimmed email (or empty).
  String get displayNameFromEmail {
    final e = email.trim();
    if (e.isEmpty) return '';
    final at = e.indexOf('@');
    if (at <= 0) return e;
    return e.substring(0, at).trim();
  }

  /// Avatar fallback: first letter of [displayNameFromEmail], uppercased.
  String get initials {
    final t = displayNameFromEmail;
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'].toString(),
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      defaultCurrency: json['default_currency'] as String? ?? 'BRL', // ignore: hardcoded
      preferredLocale: json['preferred_locale'] as String? ?? 'pt_BR',
    );
  }

  ProfileModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? defaultCurrency,
    String? preferredLocale,
  }) {
    return ProfileModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      preferredLocale: preferredLocale ?? this.preferredLocale,
    );
  }
}
