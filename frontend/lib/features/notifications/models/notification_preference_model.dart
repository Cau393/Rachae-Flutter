import 'package:flutter/foundation.dart';

@immutable
class NotificationPreferenceModel {
  const NotificationPreferenceModel({
    required this.pushExpenseCreated,
    required this.pushSettlementRecorded,
    required this.pushGroupInvitation,
    required this.emailExpenseCreated,
    required this.emailSettlementRecorded,
  });

  final bool pushExpenseCreated;
  final bool pushSettlementRecorded;
  final bool pushGroupInvitation;
  final bool emailExpenseCreated;
  final bool emailSettlementRecorded;

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    bool b(String k) => json[k] as bool;

    return NotificationPreferenceModel(
      pushExpenseCreated: b('push_expense_created'),
      pushSettlementRecorded: b('push_settlement_recorded'),
      pushGroupInvitation: b('push_group_invitation'),
      emailExpenseCreated: b('email_expense_created'),
      emailSettlementRecorded: b('email_settlement_recorded'),
    );
  }

  NotificationPreferenceModel copyWith({
    bool? pushExpenseCreated,
    bool? pushSettlementRecorded,
    bool? pushGroupInvitation,
    bool? emailExpenseCreated,
    bool? emailSettlementRecorded,
  }) {
    return NotificationPreferenceModel(
      pushExpenseCreated: pushExpenseCreated ?? this.pushExpenseCreated,
      pushSettlementRecorded:
          pushSettlementRecorded ?? this.pushSettlementRecorded,
      pushGroupInvitation: pushGroupInvitation ?? this.pushGroupInvitation,
      emailExpenseCreated: emailExpenseCreated ?? this.emailExpenseCreated,
      emailSettlementRecorded:
          emailSettlementRecorded ?? this.emailSettlementRecorded,
    );
  }
}
