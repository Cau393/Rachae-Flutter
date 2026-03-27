import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/models/pairwise_balance_row_model.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/providers/dashboard_shortcuts_providers.dart';
import 'package:frontend/features/dashboard/screens/pending_settlements_screen.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';
import 'package:frontend/features/settlements/repositories/settlement_repository.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class MockSettlementRepository extends Mock implements SettlementRepository {}

class _EmptyActivityFeed extends ActivityFeedNotifier {
  @override
  Future<List<ActivityItemModel>> build() async => const [];

  @override
  Future<void> refresh() async {
    state = const AsyncData([]);
  }
}

void main() {
  const me = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const other = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  const outgoingTxnId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  const incomingTxnId = 'dddddddd-dddd-dddd-dddd-dddddddddddd';

  final balance = const BalanceSummaryModel(
    userId: me,
    totalOwed: '0.00',
    totalOwing: '0.00',
    netBalance: '0.00',
    currency: 'BRL',
  );

  final pendingAsPayer = TransactionModel(
    id: outgoingTxnId,
    payer: const ParticipantInfo(userId: me, displayName: 'Me'),
    receiver: const ParticipantInfo(userId: other, displayName: 'Other'),
    amount: '25.00',
    currency: 'BRL',
    isConfirmed: false,
    isDisputed: false,
    createdAt: DateTime.utc(2026, 3, 23),
  );

  final pendingAsReceiver = TransactionModel(
    id: incomingTxnId,
    payer: const ParticipantInfo(userId: other, displayName: 'Other'),
    receiver: const ParticipantInfo(userId: me, displayName: 'Me'),
    amount: '30.00',
    currency: 'BRL',
    isConfirmed: false,
    isDisputed: false,
    createdAt: DateTime.utc(2026, 3, 22),
  );

  final oweRow = const PairwiseBalanceRowModel(
    userId: other,
    displayName: 'Other',
    balance: '-12.34',
    currency: 'BRL',
  );

  late MockSettlementRepository mockRepo;

  setUp(() {
    mockRepo = MockSettlementRepository();
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/dashboard/pending-settlements',
      routes: [
        GoRoute(
          path: '/dashboard/pending-settlements',
          builder: (_, _) => const PendingSettlementsScreen(),
        ),
        GoRoute(
          path: '/settle',
          builder: (_, state) => Scaffold(
            body: Text(state.uri.toString()),
          ),
        ),
      ],
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<TransactionModel> outgoing,
    required List<PairwiseBalanceRowModel> pairwise,
    GoRouter? router,
  }) async {
    final testRouter = router ?? buildRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settlementRepositoryProvider.overrideWithValue(mockRepo),
          balanceSummaryProvider.overrideWith((ref) async => balance),
          activityFeedProvider.overrideWith(_EmptyActivityFeed.new),
          pendingIncomingSettlementsProvider.overrideWith((ref) async => const []),
          pendingOutgoingSettlementsProvider.overrideWith((ref) async => outgoing),
          pairwiseBalancesProvider.overrideWith((ref) async => pairwise),
          owedToMeExpensesProvider.overrideWith((ref) async => const []),
          groupListProvider.overrideWith((ref) async => const []),
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

  testWidgets('outgoing pending section shows payer row as read-only', (tester) async {
    await pumpScreen(
      tester,
      outgoing: [pendingAsPayer],
      pairwise: const [],
    );

    expect(find.textContaining('You paid '), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    expect(find.byIcon(Icons.cancel_outlined), findsNothing);
  });

  testWidgets('outgoing pending list ignores rows where current user is receiver', (tester) async {
    await pumpScreen(
      tester,
      outgoing: [pendingAsPayer, pendingAsReceiver],
      pairwise: const [],
    );

    expect(find.textContaining('You paid '), findsOneWidget);
    expect(find.textContaining('Other sent you '), findsNothing);
  });

  testWidgets('tapping a you-owe row opens settle route with global params', (tester) async {
    final router = buildRouter();
    await pumpScreen(
      tester,
      outgoing: const [],
      pairwise: [oweRow],
      router: router,
    );

    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/settle');
    expect(router.state.uri.queryParameters['receiver_id'], other);
    expect(router.state.uri.queryParameters['amount'], '12.34');
    expect(router.state.uri.queryParameters['currency'], 'BRL');
  });

  testWidgets('RefreshIndicator is present', (tester) async {
    await pumpScreen(
      tester,
      outgoing: const [],
      pairwise: const [],
    );

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
