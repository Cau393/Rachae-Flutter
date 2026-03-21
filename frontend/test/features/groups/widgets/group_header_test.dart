import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/l10n/group_type_l10n.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/widgets/group_header.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  const createdAt = '2025-03-01T08:00:00.000Z';

  Map<String, dynamic> memberJson({
    required String userId,
    required String displayName,
    String? avatarUrl,
    String role = 'MEMBER',
  }) {
    return <String, dynamic>{
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'role': role,
      'joined_at': '2025-03-01T09:00:00.000Z',
      'invited_by': null,
    };
  }

  GroupDetailModel detail({
    String name = 'Test Group',
    String type = 'home',
    String currency = 'BRL',
    List<Map<String, dynamic>>? membersJson,
  }) {
    return GroupDetailModel.fromJson(<String, dynamic>{
      'id': '11111111-1111-1111-1111-111111111111',
      'name': name,
      'description': null,
      'type': type,
      'currency': currency,
      'simplify_debts': true,
      'created_by': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'members': membersJson ?? <Map<String, dynamic>>[],
      'net_balances': <dynamic>[],
      'created_at': createdAt,
    });
  }

  Future<void> pumpHeader(WidgetTester tester, GroupDetailModel model) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GroupHeader(model: model),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10n(WidgetTester tester) {
    final ctx = tester.element(find.byType(GroupHeader));
    return AppLocalizations.of(ctx)!;
  }

  group('GroupHeader', () {
    testWidgets('shows group name text', (tester) async {
      final m = detail(name: 'Viagem SP');
      await pumpHeader(tester, m);
      expect(find.text('Viagem SP'), findsOneWidget);
    });

    testWidgets('shows group type via l10n, not hardcoded', (tester) async {
      final m = detail(type: 'trip');
      await pumpHeader(tester, m);
      final l = l10n(tester);
      expect(find.text(groupTypeDisplayName(l, 'trip')), findsOneWidget);
      expect(find.text(l.createGroupTypeTrip), findsOneWidget);
    });

    testWidgets('currency chip shows currency code', (tester) async {
      final m = detail(currency: 'USD');
      await pumpHeader(tester, m);
      final chip = find.byType(Chip);
      expect(chip, findsOneWidget);
      expect(
        find.descendant(of: chip, matching: find.text('USD')),
        findsOneWidget,
      );
    });

    testWidgets('with three members, three CircleAvatars', (tester) async {
      final m = detail(
        membersJson: [
          memberJson(userId: 'a', displayName: 'One'),
          memberJson(userId: 'b', displayName: 'Two'),
          memberJson(userId: 'c', displayName: 'Three'),
        ],
      );
      await pumpHeader(tester, m);
      expect(find.byType(CircleAvatar), findsNWidgets(3));
    });

    testWidgets('with seven members, five avatars plus +2 overflow', (tester) async {
      final m = detail(
        membersJson: List.generate(
          7,
          (i) => memberJson(
            userId: '${1000 + i}',
            displayName: 'Member $i',
          ),
        ),
      );
      await pumpHeader(tester, m);
      expect(find.byType(CircleAvatar), findsNWidgets(6));
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('tooltips contain member display names for visible avatars',
        (tester) async {
      final m = detail(
        membersJson: [
          memberJson(userId: 'a', displayName: 'Ada Lovelace'),
          memberJson(userId: 'b', displayName: 'Bob Builder'),
          memberJson(userId: 'c', displayName: 'Carl Sagan'),
        ],
      );
      await pumpHeader(tester, m);
      final messages = tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .map((t) => t.message)
          .toList();
      expect(messages, contains('Ada Lovelace'));
      expect(messages, contains('Bob Builder'));
      expect(messages, contains('Carl Sagan'));
    });

    testWidgets('empty members list renders without error', (tester) async {
      final m = detail(membersJson: []);
      await pumpHeader(tester, m);
      expect(find.byType(CircleAvatar), findsNothing);
    });
  });
}
