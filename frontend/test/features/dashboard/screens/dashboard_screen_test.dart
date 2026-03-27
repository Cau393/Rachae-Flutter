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
import 'package:frontend/features/dashboard/providers/dashboard_shortcuts_providers.dart';
import 'package:frontend/features/dashboard/screens/dashboard_screen.dart';
import 'package:frontend/features/dashboard/widgets/balance_summary_card.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/dashboard/models/pairwise_balance_row_model.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  const fixedBalance = BalanceSummaryModel(
    userId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
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
          path: '/dashboard/pending-approvals',
          builder: (context, state) => const Scaffold(body: SizedBox()),
        ),
        GoRoute(
          path: '/dashboard/owed-to-me',
          builder: (context, state) => const Scaffold(body: SizedBox()),
        ),
        GoRoute(
          path: '/dashboard/pending-settlements',
          builder: (context, state) => const Scaffold(body: SizedBox()),
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
          pendingIncomingSettlementsProvider.overrideWith((ref) async => const []),
          pendingOutgoingSettlementsProvider.overrideWith((ref) async => const []),
          pairwiseBalancesProvider.overrideWith((ref) async => const []),
          owedToMeExpensesProvider.overrideWith((ref) async => const []),
          groupListProvider.overrideWith((ref) async => const []),
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

    testWidgets('shortcut buttons show Badge counts when pending lists non-empty',
        (tester) async {
      final router = buildRouter();
      setPhysicalSize(tester, const ui.Size(400, 800));
      addTearDown(() => resetPhysicalSize(tester));

      final payer = const ParticipantInfo(userId: 'a', displayName: 'A');
      final receiver = const ParticipantInfo(userId: 'b', displayName: 'B');
      final at = DateTime.utc(2025, 1, 1);
      final txn = TransactionModel(
        id: 't1',
        payer: payer,
        receiver: receiver,
        amount: '10.00',
        currency: 'BRL',
        isConfirmed: false,
        isDisputed: false,
        createdAt: at,
      );
      final oweRow = PairwiseBalanceRowModel(
        userId: 'u1',
        displayName: 'Alex',
        balance: '5.00',
        currency: 'BRL',
      );
      final iOweRows = [
        const PairwiseBalanceRowModel(
          userId: 'u2',
          displayName: 'Bob',
          balance: '-1.00',
          currency: 'BRL',
        ),
        const PairwiseBalanceRowModel(
          userId: 'u3',
          displayName: 'Cara',
          balance: '-2.00',
          currency: 'BRL',
        ),
        const PairwiseBalanceRowModel(
          userId: 'u4',
          displayName: 'Dan',
          balance: '-3.00',
          currency: 'BRL',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            balanceSummaryProvider.overrideWith((ref) async => fixedBalance),
            activityFeedProvider.overrideWith(_EmptyActivityFeed.new),
            pendingIncomingSettlementsProvider.overrideWith(
              (ref) async => [txn, txn],
            ),
            pendingOutgoingSettlementsProvider.overrideWith(
              (ref) async => const [],
            ),
            pairwiseBalancesProvider.overrideWith((ref) async => iOweRows),
            owedToMeExpensesProvider.overrideWith((ref) async => [oweRow]),
            groupListProvider.overrideWith((ref) async => const []),
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

      expect(find.byType(Badge), findsNWidgets(3));
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shortcut buttons navigate to the expected dashboard routes', (tester) async {
      final router = buildRouter();
      await pumpDashboard(
        tester,
        physicalSize: const ui.Size(400, 800),
        router: router,
      );

      final ctx = tester.element(find.byType(DashboardScreen));
      final l10n = AppLocalizations.of(ctx)!;

      await tester.tap(find.widgetWithText(OutlinedButton, l10n.dashboardShortcutPendingApprovals));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/dashboard/pending-approvals');

      router.go('/dashboard');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, l10n.dashboardShortcutOwedToYou));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/dashboard/owed-to-me');

      router.go('/dashboard');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, l10n.dashboardShortcutPendingSettlements));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/dashboard/pending-settlements');
    });
  });
}

class _EmptyActivityFeed extends ActivityFeedNotifier {
  @override
  Future<List<ActivityItemModel>> build() async => const [];

  @override
  Future<void> refresh() async {
    state = const AsyncData([]);
  }
}
