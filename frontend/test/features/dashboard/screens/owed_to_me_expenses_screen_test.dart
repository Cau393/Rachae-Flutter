import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/models/pairwise_balance_row_model.dart';
import 'package:frontend/features/dashboard/providers/dashboard_shortcuts_providers.dart';
import 'package:frontend/features/dashboard/screens/owed_to_me_expenses_screen.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  const friendId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  final owedRow = const PairwiseBalanceRowModel(
    userId: friendId,
    displayName: 'Chris',
    balance: '87.65',
    currency: 'BRL',
  );

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/dashboard/owed-to-me',
      routes: [
        GoRoute(
          path: '/dashboard/owed-to-me',
          builder: (_, _) => const OwedToMeExpensesScreen(),
        ),
        GoRoute(
          path: '/friends/:id',
          builder: (_, state) => Scaffold(
            body: Text('friend:${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<PairwiseBalanceRowModel> rows,
    GoRouter? router,
  }) async {
    final testRouter = router ?? buildRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          owedToMeExpensesProvider.overrideWith((ref) async => rows),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: testRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a row navigates to friend detail', (tester) async {
    final router = buildRouter();
    await pumpScreen(
      tester,
      rows: [owedRow],
      router: router,
    );

    await tester.tap(find.text('Chris'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/friends/$friendId');
  });

  testWidgets('shows empty state when there are no owed-to-you rows', (tester) async {
    await pumpScreen(
      tester,
      rows: const [],
    );

    final context = tester.element(find.byType(OwedToMeExpensesScreen));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.dashboardOwedToYouEmpty), findsOneWidget);
  });

  testWidgets('RefreshIndicator is present', (tester) async {
    await pumpScreen(
      tester,
      rows: [owedRow],
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
