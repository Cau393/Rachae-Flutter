import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/widgets/activity_feed.dart';
import 'package:frontend/features/dashboard/widgets/expense_list_tile.dart';
import 'package:frontend/features/dashboard/widgets/settlement_list_tile.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  final createdAt = DateTime.utc(2024, 1, 1);

  final expenseItem = ExpenseActivity(
    id: 'exp-1',
    type: 'expense',
    groupId: null,
    groupName: null,
    amount: '10.00',
    currency: 'BRL',
    createdAt: createdAt,
    description: 'Coffee',
    paidById: 'u1',
    paidByName: 'Bob',
  );

  final transactionItem = TransactionActivity(
    id: 'txn-1',
    type: 'transaction',
    groupId: null,
    groupName: null,
    amount: '30.00',
    currency: 'BRL',
    createdAt: createdAt,
    payerId: 'bob',
    payerName: 'Bob',
    receiverId: 'ana',
    receiverName: 'Ana',
    note: null,
    isConfirmed: true,
  );

  group('ActivityFeed', () {
    testWidgets('loading: CircularProgressIndicator; no ExpenseListTile', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activityFeedProvider.overrideWith(_LoadingActivityFeed.new),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: ActivityFeed(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ExpenseListTile), findsNothing);
    });

    testWidgets('error: error text + retry triggers invalidate', (tester) async {
      _errorFeedBuildCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activityFeedProvider.overrideWith(_ErrorActivityFeed.new),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: ActivityFeed(),
            ),
          ),
        ),
      );
      await tester.pump();
      final ctx = tester.element(find.byType(ActivityFeed));
      final strings = AppLocalizations.of(ctx)!;
      expect(find.text(strings.errorGeneric), findsOneWidget);
      expect(find.text(strings.retryLabel), findsOneWidget);
      expect(_errorFeedBuildCount, 1);
      await tester.tap(find.text(strings.retryLabel));
      await tester.pump();
      expect(_errorFeedBuildCount, greaterThan(1));
    });

    testWidgets('empty: dashboardNoActivity', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activityFeedProvider.overrideWith(_EmptyActivityFeed.new),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: ActivityFeed(),
            ),
          ),
        ),
      );
      await tester.pump();
      final ctx = tester.element(find.byType(ActivityFeed));
      final strings = AppLocalizations.of(ctx)!;
      expect(find.text(strings.dashboardNoActivity), findsOneWidget);
    });

    testWidgets('list: one ExpenseListTile and one SettlementListTile', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activityFeedProvider.overrideWith(
              () => _ListActivityFeed([expenseItem, transactionItem]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: ActivityFeed(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ExpenseListTile), findsOneWidget);
      expect(find.byType(SettlementListTile), findsOneWidget);
    });

    testWidgets('expense tile tap navigates to expense detail', (tester) async {
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => ProviderScope(
              overrides: [
                activityFeedProvider.overrideWith(
                  () => _ListActivityFeed([expenseItem]),
                ),
              ],
              child: const Scaffold(body: ActivityFeed()),
            ),
          ),
          GoRoute(
            path: '/expenses/:id',
            builder: (context, state) =>
                Text('EXPENSE_${state.pathParameters['id']}'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExpenseListTile));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/expenses/exp-1');
      expect(find.text('EXPENSE_exp-1'), findsOneWidget);
    });
  });
}

/// Stays in [AsyncLoading] forever (never completes).
class _LoadingActivityFeed extends ActivityFeedNotifier {
  @override
  Future<List<ActivityItemModel>> build() async {
    await Completer<void>().future;
    return const [];
  }
}

var _errorFeedBuildCount = 0;

class _ErrorActivityFeed extends ActivityFeedNotifier {
  @override
  Future<List<ActivityItemModel>> build() async {
    _errorFeedBuildCount++;
    throw Exception('fail');
  }
}

class _EmptyActivityFeed extends ActivityFeedNotifier {
  @override
  Future<List<ActivityItemModel>> build() async => const [];
}

class _ListActivityFeed extends ActivityFeedNotifier {
  _ListActivityFeed(this._items);
  final List<ActivityItemModel> _items;

  @override
  Future<List<ActivityItemModel>> build() async => _items;
}
