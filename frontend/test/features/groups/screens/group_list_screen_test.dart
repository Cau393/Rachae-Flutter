import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/screens/group_list_screen.dart';
import 'package:frontend/features/groups/widgets/group_card.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  final groupA = GroupSummaryModel.fromJson({
    'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'name': 'Alpha',
    'type': 'home',
    'currency': 'BRL',
    'member_count': 2,
    'your_net_balance': '10.00',
    'created_at': '2025-01-01T00:00:00.000Z',
  });

  final groupB = GroupSummaryModel.fromJson({
    'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'name': 'Beta',
    'type': 'trip',
    'currency': 'BRL',
    'member_count': 3,
    'your_net_balance': '-5.00',
    'created_at': '2025-01-02T00:00:00.000Z',
  });

  void setPhysicalSize(WidgetTester tester, ui.Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
  }

  void resetPhysicalSize(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/groups',
      routes: [
        GoRoute(
          path: '/groups',
          builder: (context, state) => const GroupListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) =>
                  const Scaffold(body: Text('new_group_placeholder')),
            ),
            GoRoute(
              path: ':groupId',
              builder: (context, state) =>
                  const Scaffold(body: Text('detail_placeholder')),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required GoRouter router,
    required List<Override> overrides,
    bool settle = true,
  }) async {
    setPhysicalSize(tester, const ui.Size(400, 800));
    addTearDown(() => resetPhysicalSize(tester));

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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('GroupListScreen', () {
    testWidgets('loading: CircularProgressIndicator, no GroupCard', (tester) async {
      final completer = Completer<List<GroupSummaryModel>>();
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        settle: false,
        overrides: [
          groupListProvider.overrideWith(
            (ref) => completer.future,
          ),
        ],
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GroupCard), findsNothing);
    });

    testWidgets('error: errorGeneric and retry; no GroupCard', (tester) async {
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: [
          groupListProvider.overrideWith(
            (ref) async => throw Exception('fail'),
          ),
        ],
      );

      final ctx = tester.element(find.byType(GroupListScreen));
      final l10n = AppLocalizations.of(ctx)!;

      expect(find.text(l10n.errorGeneric), findsOneWidget);
      expect(find.text(l10n.retryLabel), findsOneWidget);
      expect(find.byType(GroupCard), findsNothing);
    });

    testWidgets('empty list: groupsEmpty', (tester) async {
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: [
          groupListProvider.overrideWith((ref) async => const []),
        ],
      );

      final ctx = tester.element(find.byType(GroupListScreen));
      final l10n = AppLocalizations.of(ctx)!;

      expect(find.text(l10n.groupsEmpty), findsOneWidget);
    });

    testWidgets('two groups: two GroupCards', (tester) async {
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: [
          groupListProvider.overrideWith((ref) async => [groupA, groupB]),
        ],
      );

      expect(find.byType(GroupCard), findsNWidgets(2));
    });

    testWidgets('tap first card navigates to /groups/{id}', (tester) async {
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: [
          groupListProvider.overrideWith((ref) async => [groupA, groupB]),
        ],
      );

      await tester.tap(find.byType(GroupCard).first);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/groups/${groupA.id}');
    });

    testWidgets('FAB has groupsCreateFab tooltip', (tester) async {
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: [
          groupListProvider.overrideWith((ref) async => const []),
        ],
      );

      final ctx = tester.element(find.byType(GroupListScreen));
      final l10n = AppLocalizations.of(ctx)!;

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.tooltip, l10n.groupsCreateFab);
    });

    testWidgets('RefreshIndicator present', (tester) async {
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: [
          groupListProvider.overrideWith((ref) async => const []),
        ],
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('AppBar has title, no actions', (tester) async {
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: [
          groupListProvider.overrideWith((ref) async => const []),
        ],
      );

      final ctx = tester.element(find.byType(GroupListScreen));
      final l10n = AppLocalizations.of(ctx)!;

      expect(find.text(l10n.groupsTitle), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isNull);
    });
  });
}
