import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';
import 'package:frontend/features/groups/widgets/member_list_tile.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  GroupMemberModel member({
    String userId = 'u1',
    String displayName = 'Ada',
    String? avatarUrl,
    String role = 'MEMBER',
  }) {
    return GroupMemberModel.fromJson(<String, dynamic>{
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'role': role,
      'joined_at': '2025-03-01T09:00:00.000Z',
      'invited_by': null,
    });
  }

  Future<void> pumpTile(
    WidgetTester tester, {
    required MemberListTile tile,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: tile),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10n(WidgetTester tester) {
    final ctx = tester.element(find.byType(MemberListTile));
    return AppLocalizations.of(ctx)!;
  }

  group('MemberListTile', () {
    testWidgets('canManage true and not current user: PopupMenuButton and CircleAvatar',
        (tester) async {
      await pumpTile(
        tester,
        tile: MemberListTile(
          member: member(displayName: 'Bob'),
          isCurrentUser: false,
          canManage: true,
          onChangeRole: (_) {},
          onRemove: () {},
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('canManage false: no trailing menu', (tester) async {
      await pumpTile(
        tester,
        tile: MemberListTile(
          member: member(),
          isCurrentUser: false,
          canManage: false,
          onChangeRole: (_) {},
          onRemove: () {},
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsNothing);
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.trailing, isNull);
    });

    testWidgets('canManage true but canManageThisMember false: no trailing menu',
        (tester) async {
      await pumpTile(
        tester,
        tile: MemberListTile(
          member: member(),
          isCurrentUser: false,
          canManage: true,
          canManageThisMember: false,
          onChangeRole: (_) {},
          onRemove: () {},
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('isCurrentUser true: title uses groupMemberCurrentUserSuffix',
        (tester) async {
      await pumpTile(
        tester,
        tile: MemberListTile(
          member: member(displayName: 'Self'),
          isCurrentUser: true,
          canManage: false,
          onChangeRole: (_) {},
          onRemove: () {},
        ),
      );

      final l = l10n(tester);
      expect(
        find.text('${member(displayName: 'Self').displayName} ${l.groupMemberCurrentUserSuffix}'),
        findsOneWidget,
      );
    });

    testWidgets('popup lists only roles other than current plus remove', (tester) async {
      await pumpTile(
        tester,
        tile: MemberListTile(
          member: member(role: 'MEMBER'),
          isCurrentUser: false,
          canManage: true,
          onChangeRole: (_) {},
          onRemove: () {},
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      final items = tester.widgetList<PopupMenuItem<String>>(
        find.byType(PopupMenuItem<String>),
      );
      final values = items.map((e) => e.value).whereType<String>().toList();

      expect(values, contains('remove'));
      expect(values, isNot(contains('MEMBER')));
      expect(values, containsAll(<String>['ADMIN', 'VIEWER']));
    });
  });
}
