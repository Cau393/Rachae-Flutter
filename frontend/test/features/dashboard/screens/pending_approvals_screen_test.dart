import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/providers/dashboard_shortcuts_providers.dart';
import 'package:frontend/features/dashboard/screens/pending_approvals_screen.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';
import 'package:frontend/features/settlements/repositories/settlement_repository.dart';
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
  const txnId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

  final balance = const BalanceSummaryModel(
    userId: me,
    totalOwed: '0.00',
    totalOwing: '0.00',
    netBalance: '0.00',
    currency: 'BRL',
  );

  final incomingPending = TransactionModel(
    id: txnId,
    payer: const ParticipantInfo(userId: other, displayName: 'Other'),
    receiver: const ParticipantInfo(userId: me, displayName: 'Me'),
    amount: '25.00',
    currency: 'BRL',
    isConfirmed: false,
    isDisputed: false,
    createdAt: DateTime.utc(2026, 3, 23),
  );

  final outgoingPending = TransactionModel(
    id: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
    payer: const ParticipantInfo(userId: me, displayName: 'Me'),
    receiver: const ParticipantInfo(userId: other, displayName: 'Other'),
    amount: '10.00',
    currency: 'BRL',
    isConfirmed: false,
    isDisputed: false,
    createdAt: DateTime.utc(2026, 3, 22),
  );

  late MockSettlementRepository mockRepo;

  setUp(() {
    mockRepo = MockSettlementRepository();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<TransactionModel> incoming,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settlementRepositoryProvider.overrideWithValue(mockRepo),
          balanceSummaryProvider.overrideWith((ref) async => balance),
          activityFeedProvider.overrideWith(_EmptyActivityFeed.new),
          pendingIncomingSettlementsProvider.overrideWith((ref) async => incoming),
          pendingOutgoingSettlementsProvider.overrideWith((ref) async => const []),
          pairwiseBalancesProvider.overrideWith((ref) async => const []),
          owedToMeExpensesProvider.overrideWith((ref) async => const []),
          groupListProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PendingApprovalsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('receiver can confirm a pending incoming transaction', (tester) async {
    when(() => mockRepo.confirmTransaction(txnId)).thenAnswer((_) async {
      return TransactionModel(
        id: txnId,
        payer: incomingPending.payer,
        receiver: incomingPending.receiver,
        amount: incomingPending.amount,
        currency: incomingPending.currency,
        isConfirmed: true,
        isDisputed: false,
        createdAt: incomingPending.createdAt,
      );
    });

    await pumpScreen(tester, incoming: [incomingPending]);

    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();

    verify(() => mockRepo.confirmTransaction(txnId)).called(1);
  });

  testWidgets('receiver can dispute pending incoming transaction via confirmation dialog', (tester) async {
    when(() => mockRepo.disputeTransaction(txnId)).thenAnswer((_) async {
      return TransactionModel(
        id: txnId,
        payer: incomingPending.payer,
        receiver: incomingPending.receiver,
        amount: incomingPending.amount,
        currency: incomingPending.currency,
        isConfirmed: false,
        isDisputed: true,
        createdAt: incomingPending.createdAt,
      );
    });

    await pumpScreen(tester, incoming: [incomingPending]);
    final context = tester.element(find.byType(PendingApprovalsScreen));
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.byIcon(Icons.cancel_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.confirmLabel));
    await tester.pumpAndSettle();

    verify(() => mockRepo.disputeTransaction(txnId)).called(1);
  });

  testWidgets('list ignores rows where current user is payer', (tester) async {
    await pumpScreen(
      tester,
      incoming: [incomingPending, outgoingPending],
    );

    expect(find.textContaining('Other sent you '), findsOneWidget);
    expect(find.textContaining('You paid '), findsNothing);
  });

  testWidgets('RefreshIndicator is present', (tester) async {
    await pumpScreen(tester, incoming: [incomingPending]);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
