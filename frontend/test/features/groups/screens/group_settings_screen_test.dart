import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';
import 'package:frontend/features/currencies/providers/currency_providers.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/providers/group_members_provider.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';
import 'package:frontend/features/groups/repositories/group_repository.dart';
import 'package:frontend/features/groups/screens/group_settings_screen.dart';
import 'package:frontend/features/groups/widgets/member_list_tile.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class MockUser extends Mock implements User {}

class _MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  const gid = '11111111-1111-1111-1111-111111111111';
  const adminUid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

  late MockUser mockUser;
  late _MockGroupRepository mockRepo;

  GroupDetailModel detail({String name = 'Trip Group'}) {
    return GroupDetailModel.fromJson(<String, dynamic>{
      'id': gid,
      'name': name,
      'description': null,
      'type': 'trip',
      'currency': 'BRL',
      'simplify_debts': true,
      'created_by': adminUid,
      'members': <dynamic>[
        <String, dynamic>{
          'user_id': adminUid,
          'display_name': 'Admin User',
          'avatar_url': null,
          'role': 'ADMIN',
          'joined_at': '2025-03-01T09:00:00.000Z',
          'invited_by': null,
        },
        <String, dynamic>{
          'user_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
          'display_name': 'Other Admin',
          'avatar_url': null,
          'role': 'ADMIN',
          'joined_at': '2025-03-01T09:00:00.000Z',
          'invited_by': null,
        },
      ],
      'net_balances': <dynamic>[],
      'created_at': '2025-03-01T08:00:00.000Z',
    });
  }

  List<Override> baseOverrides({
    required GroupDetailModel d,
    List<GroupMemberModel>? members,
  }) {
    final m = members ?? d.members;
    return [
      groupRepositoryProvider.overrideWithValue(mockRepo),
      groupDetailProvider(gid).overrideWith((ref) async => d),
      groupMembersProvider(gid).overrideWith((ref) async => m),
      groupListProvider.overrideWith((ref) async => []),
      currencyListProvider.overrideWith(
        (ref) async => [
          CurrencyModel.brl(),
          const CurrencyModel(code: 'USD', name: 'US Dollar', symbol: r'$'),
        ],
      ),
      authNotifierProvider.overrideWith(
        () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
      ),
    ];
  }

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/groups/$gid/settings',
      routes: [
        GoRoute(
          path: '/groups',
          builder: (_, _) => const Scaffold(body: Text('groups_list')),
        ),
        GoRoute(
          path: '/groups/:groupId',
          builder: (_, _) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: 'settings',
              builder: (context, state) => GroupSettingsScreen(
                groupId: state.pathParameters['groupId']!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> pumpSettings(
    WidgetTester tester, {
    required GoRouter router,
    required List<Override> overrides,
  }) async {
    tester.view.physicalSize = const ui.Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    mockUser = MockUser();
    mockRepo = _MockGroupRepository();
    when(() => mockUser.id).thenReturn(adminUid);
    when(() => mockRepo.updateGroup(any(), any())).thenAnswer((invocation) async {
      final id = invocation.positionalArguments[0] as String;
      final d = detail();
      return GroupDetailModel.fromJson(<String, dynamic>{
        'id': id,
        'name': d.name,
        'description': d.description,
        'type': d.type,
        'currency': d.currency,
        'simplify_debts': d.simplifyDebts,
        'created_by': d.createdBy,
        'members': d.members
            .map(
              (e) => <String, dynamic>{
                'user_id': e.userId,
                'display_name': e.displayName,
                'avatar_url': e.avatarUrl,
                'role': e.role,
                'joined_at': e.joinedAt.toUtc().toIso8601String(),
                'invited_by': e.invitedBy,
              },
            )
            .toList(),
        'net_balances': <dynamic>[],
        'created_at': d.createdAt.toUtc().toIso8601String(),
      });
    });
    when(() => mockRepo.deleteGroup(any())).thenAnswer((_) async {});
    when(() => mockRepo.leaveGroup(any())).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(<String, dynamic>{});
  });

  group('GroupSettingsScreen', () {
    testWidgets('name field is pre-populated from group detail', (tester) async {
      final d = detail(name: 'Alpha Group');
      final router = buildRouter();
      await pumpSettings(
        tester,
        router: router,
        overrides: baseOverrides(d: d),
      );

      final tf = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(tf.controller?.text, 'Alpha Group');
    });

    testWidgets('tapping Delete group shows confirmation dialog', (tester) async {
      final router = buildRouter();
      await pumpSettings(
        tester,
        router: router,
        overrides: baseOverrides(d: detail()),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GroupSettingsScreen)),
      )!;
      await tester.ensureVisible(find.text(l10n.groupSettingsDeleteGroup));
      await tester.tap(find.text(l10n.groupSettingsDeleteGroup).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.groupSettingsDeleteConfirm), findsOneWidget);
    });

    testWidgets('confirming delete calls repository deleteGroup', (tester) async {
      final router = buildRouter();
      await pumpSettings(
        tester,
        router: router,
        overrides: baseOverrides(d: detail()),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GroupSettingsScreen)),
      )!;
      await tester.ensureVisible(find.text(l10n.groupSettingsDeleteGroup));
      await tester.tap(find.text(l10n.groupSettingsDeleteGroup).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.confirmLabel));
      await tester.pumpAndSettle();

      verify(() => mockRepo.deleteGroup(gid)).called(1);
    });

    testWidgets('dismissing delete dialog does not call deleteGroup', (tester) async {
      final router = buildRouter();
      await pumpSettings(
        tester,
        router: router,
        overrides: baseOverrides(d: detail()),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GroupSettingsScreen)),
      )!;
      await tester.ensureVisible(find.text(l10n.groupSettingsDeleteGroup));
      await tester.tap(find.text(l10n.groupSettingsDeleteGroup).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.cancelLabel));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepo.deleteGroup(any()));
    });

    testWidgets('tapping Leave group shows leave confirmation dialog', (tester) async {
      final router = buildRouter();
      final d = detail();
      await pumpSettings(
        tester,
        router: router,
        overrides: baseOverrides(d: d),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GroupSettingsScreen)),
      )!;
      await tester.ensureVisible(find.text(l10n.groupSettingsLeaveGroup));
      await tester.tap(find.text(l10n.groupSettingsLeaveGroup));
      await tester.pumpAndSettle();

      expect(find.text(l10n.groupSettingsLeaveConfirm), findsOneWidget);
    });

    testWidgets('member list renders MemberListTile with canManage true',
        (tester) async {
      final router = buildRouter();
      await pumpSettings(
        tester,
        router: router,
        overrides: baseOverrides(d: detail()),
      );

      expect(find.byType(MemberListTile), findsWidgets);
      final tile = tester.widget<MemberListTile>(find.byType(MemberListTile).first);
      expect(tile.canManage, isTrue);
    });

    testWidgets('save after failed update shows errorGeneric snackbar', (tester) async {
      when(() => mockRepo.updateGroup(any(), any())).thenThrow(Exception('fail'));

      final router = buildRouter();
      await pumpSettings(
        tester,
        router: router,
        overrides: baseOverrides(d: detail()),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GroupSettingsScreen)),
      )!;
      await tester.enterText(find.byType(TextFormField).first, 'X');
      await tester.pump();

      await tester.ensureVisible(find.text(l10n.saveLabel));
      await tester.tap(find.text(l10n.saveLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(l10n.errorGeneric), findsOneWidget);
    });

    testWidgets('save calls updateGroup with only changed name field', (tester) async {
      when(() => mockRepo.updateGroup(any(), any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        final body = Map<String, dynamic>.from(
          invocation.positionalArguments[1] as Map,
        );
        final base = detail();
        return GroupDetailModel.fromJson(<String, dynamic>{
          'id': id,
          'name': body['name'] as String? ?? base.name,
          'description': base.description,
          'type': body['type'] as String? ?? base.type,
          'currency': body['currency'] as String? ?? base.currency,
          'simplify_debts': body['simplify_debts'] as bool? ?? base.simplifyDebts,
          'created_by': base.createdBy,
          'members': base.members
              .map(
                (e) => <String, dynamic>{
                  'user_id': e.userId,
                  'display_name': e.displayName,
                  'avatar_url': e.avatarUrl,
                  'role': e.role,
                  'joined_at': e.joinedAt.toUtc().toIso8601String(),
                  'invited_by': e.invitedBy,
                },
              )
              .toList(),
          'net_balances': <dynamic>[],
          'created_at': base.createdAt.toUtc().toIso8601String(),
        });
      });

      final router = buildRouter();
      await pumpSettings(
        tester,
        router: router,
        overrides: baseOverrides(d: detail()),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GroupSettingsScreen)),
      )!;
      await tester.enterText(find.byType(TextFormField).first, 'NewName');
      await tester.pump();

      await tester.ensureVisible(find.text(l10n.saveLabel));
      await tester.tap(find.text(l10n.saveLabel));
      await tester.pumpAndSettle();

      verify(() => mockRepo.updateGroup(gid, {'name': 'NewName'})).called(1);
    });
  });
}
