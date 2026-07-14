// Viewport: same effect as binding.window.physicalSizeTestValue + dpr 1.0
// (logical width 400 mobile / 900 wide). Reset via resetPhysicalSize().
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shell/app_shell.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AppShell(
            currentIndex: 0,
            child: SizedBox(),
          ),
        ),
        GoRoute(
          path: '/groups',
          builder: (context, state) => const Scaffold(body: SizedBox()),
        ),
      ],
    );
  }

  void setPhysicalSize(WidgetTester tester, ui.Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
  }

  void resetPhysicalSize(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  Future<void> pumpShell(
    WidgetTester tester, {
    required ui.Size physicalSize,
    required GoRouter router,
  }) async {
    setPhysicalSize(tester, physicalSize);
    addTearDown(() => resetPhysicalSize(tester));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [],
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

  group('AppShell', () {
    testWidgets('mobile: BottomNavigationBar, no NavigationRail', (tester) async {
      final router = buildRouter();
      await pumpShell(tester, physicalSize: const ui.Size(400, 800), router: router);

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('wide: NavigationRail, no BottomNavigationBar', (tester) async {
      final router = buildRouter();
      await pumpShell(tester, physicalSize: const ui.Size(900, 600), router: router);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('nav labels: navDashboard, navGroups, navFriends, navProfile', (tester) async {
      final router = buildRouter();
      await pumpShell(tester, physicalSize: const ui.Size(400, 800), router: router);

      final ctx = tester.element(find.byType(AppShell));
      final l10n = AppLocalizations.of(ctx)!;
      expect(find.text(l10n.navDashboard), findsOneWidget);
      expect(find.text(l10n.navGroups), findsOneWidget);
      expect(find.text(l10n.navFriends), findsOneWidget);
      expect(find.text(l10n.navProfile), findsOneWidget);
    });

    testWidgets('tap Groups tab navigates to /groups', (tester) async {
      final router = buildRouter();
      await pumpShell(tester, physicalSize: const ui.Size(400, 800), router: router);

      final ctx = tester.element(find.byType(AppShell));
      final l10n = AppLocalizations.of(ctx)!;
      await tester.tap(find.text(l10n.navGroups));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/groups');
    });

  });
}
