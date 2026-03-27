import 'package:flutter/foundation.dart';

@immutable
class AdsStatusModel {
  const AdsStatusModel({
    required this.isAdFree,
    this.subscriptionStatus,
    this.planExpiresAt,
    this.planType,
  });

  final bool isAdFree;
  final String? subscriptionStatus;
  final DateTime? planExpiresAt;
  final String? planType;

  factory AdsStatusModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AdsStatusModel(
      isAdFree: data['is_ad_free'] as bool,
      subscriptionStatus: data['subscription_status'] as String?,
      planExpiresAt: data['plan_expires_at'] == null
          ? null
          : DateTime.tryParse(data['plan_expires_at'].toString()),
      planType: data['plan_type'] as String?,
    );
  }
}
