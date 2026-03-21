// ignore_for_file: library_private_types_in_public_api

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/screens/dashboard_screen.dart';
import 'package:frontend/features/dashboard/widgets/balance_summary_card.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  const fixedBalance = BalanceSummaryModel(
    totalOwed: '45.00',
    totalOwing: '120.50',
    netBalance: '-75.50',
    currency: 'BRL',
  );

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
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/expenses/new',
          builder: (context, state) => const Scaffold(body: SizedBox()),
        ),
      ],
    );
  }

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required ui.Size physicalSize,
    required GoRouter router,
    bool balanceError = false,
  }) async {
    setPhysicalSize(tester, physicalSize);
    addTearDown(() => resetPhysicalSize(tester));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          balanceError
              ? balanceSummaryProvider.overrideWith(
                  (ref) async => throw Exception('fail'),
                )
              : balanceSummaryProvider.overrideWith(
                  (ref) async => fixedBalance,
                ),
          activityFeedProvider.overrideWith(_EmptyActivityFeed.new),
        ],
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

  group('DashboardScreen', () {
    testWidgets('AppBar title, BalanceSummaryCard, FAB, RefreshIndicator', (tester) async {
      final router = buildRouter();
      await pumpDashboard(
        tester,
        physicalSize: const ui.Size(400, 800),
        router: router,
      );

      final ctx = tester.element(find.byType(DashboardScreen));
      final l10n = AppLocalizations.of(ctx)!;

      expect(find.text(l10n.dashboardTitle), findsOneWidget);
      expect(find.byType(BalanceSummaryCard), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.tooltip, l10n.dashboardAddExpense);
    });

    testWidgets('wide layout: Row present', (tester) async {
      final router = buildRouter();
      await pumpDashboard(
        tester,
        physicalSize: const ui.Size(900, 800),
        router: router,
      );

      expect(
        find.descendant(
          of: find.byType(DashboardScreen),
          matching: find.byType(Row),
        ),
        findsWidgets,
      );
    });

    testWidgets('balance error: error UI, no BalanceSummaryCard', (tester) async {
      final router = buildRouter();
      await pumpDashboard(
        tester,
        physicalSize: const ui.Size(400, 800),
        router: router,
        balanceError: true,
      );

      final ctx = tester.element(find.byType(DashboardScreen));
      final l10n = AppLocalizations.of(ctx)!;

      expect(find.text(l10n.errorGeneric), findsOneWidget);
      expect(find.byType(BalanceSummaryCard), findsNothing);
    });

    testWidgets('FAB tap navigates to /expenses/new', (tester) async {
      final router = buildRouter();
      await pumpDashboard(
        tester,
        physicalSize: const ui.Size(400, 800),
        router: router,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/expenses/new');
    });
  });
}

class _EmptyActivityFeed extends ActivityFeedNotifier {
  @override
  Future<List<ActivityItemModel>> build() async => const [];
}
