import 'package:flutter/foundation.dart';

@immutable
class ReportPerPersonSpendModel {
  const ReportPerPersonSpendModel({
    required this.userId,
    required this.displayName,
    required this.totalPaid,
    required this.totalOwed,
    required this.net,
  });

  final String userId;
  final String displayName;
  final String totalPaid;
  final String totalOwed;
  final String net;

  factory ReportPerPersonSpendModel.fromJson(Map<String, dynamic> json) {
    return ReportPerPersonSpendModel(
      userId: json['user_id'].toString(),
      displayName: json['display_name'] as String,
      totalPaid: json['total_paid'].toString(),
      totalOwed: json['total_owed'].toString(),
      net: json['net'].toString(),
    );
  }
}

@immutable
class GroupReportModel {
  const GroupReportModel({
    required this.groupId,
    required this.groupName,
    required this.currency,
    this.dateFrom,
    this.dateTo,
    required this.totalSpent,
    required this.perPersonSpend,
    required this.expenses,
    required this.settlements,
  });

  final String groupId;
  final String groupName;
  final String currency;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String totalSpent;
  final List<ReportPerPersonSpendModel> perPersonSpend;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> settlements;

  factory GroupReportModel.fromJson(Map<String, dynamic> json) {
    final perPerson = (json['per_person_spend'] as List<dynamic>? ?? [])
        .map(
          (e) => ReportPerPersonSpendModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
    final expenses = (json['expenses'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final settlements = (json['settlements'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return GroupReportModel(
      groupId: json['group_id'].toString(),
      groupName: json['group_name'] as String,
      currency: json['currency'] as String,
      dateFrom: parseDate(json['date_from']),
      dateTo: parseDate(json['date_to']),
      totalSpent: json['total_spent'].toString(),
      perPersonSpend: perPerson,
      expenses: expenses,
      settlements: settlements,
    );
  }
}
