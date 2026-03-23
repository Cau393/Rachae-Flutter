// ignore_for_file: library_private_types_in_public_api

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/repositories/dashboard_repository.dart';
import 'package:frontend/features/friends/models/friend_balance_model.dart';
import 'package:frontend/features/friends/providers/friend_balance_provider.dart';
import 'package:frontend/features/friends/providers/friends_repository_provider.dart';
import 'package:frontend/features/friends/repositories/friends_repository.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';
import 'package:frontend/features/settlements/providers/settle_up_notifier.dart';
import 'package:frontend/features/settlements/repositories/settlement_repository.dart';

class _MockSettlementRepository extends Mock implements SettlementRepository {}

class _MockFriendsRepository extends Mock implements FriendsRepository {}

class _MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  const receiverId = '22222222-2222-2222-2222-222222222222';

  late _MockSettlementRepository mockSettlement;
  late _MockFriendsRepository mockFriends;
  late _MockDashboardRepository mockDashboard;
  late ProviderContainer container;

  final balanceSummary = BalanceSummaryModel(
    userId: '11111111-1111-1111-1111-111111111111',
    totalOwed: '0.00',
    totalOwing: '0.00',
    netBalance: '0.00',
    currency: 'BRL',
  );

  FriendBalanceModel friendBalance() => FriendBalanceModel.fromJson(<String, dynamic>{
        'balance': '0.00',
        'currency': 'BRL',
      });

  TransactionModel transaction() => TransactionModel.fromJson(<String, dynamic>{
        'id': 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
        'group_id': null,
        'payer': <String, dynamic>{
          'user_id': '11111111-1111-1111-1111-111111111111',
          'display_name': 'Me',
          'avatar_url': null,
        },
        'receiver': <String, dynamic>{
          'user_id': receiverId,
          'display_name': 'Them',
          'avatar_url': null,
        },
        'amount': '50.00',
        'currency': 'BRL',
        'note': null,
        'is_confirmed': false,
        'is_disputed': false,
        'created_at': '2026-03-20T15:30:00Z',
      });

  setUp(() {
    mockSettlement = _MockSettlementRepository();
    mockFriends = _MockFriendsRepository();
    mockDashboard = _MockDashboardRepository();
    container = ProviderContainer(
      overrides: [
        settlementRepositoryProvider.overrideWithValue(mockSettlement),
        friendsRepositoryProvider.overrideWithValue(mockFriends),
        dashboardRepositoryProvider.overrideWithValue(mockDashboard),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'recordPayment calls createTransaction and on success invalidates '
    'friendBalanceProvider(receiverId), balanceSummaryProvider, activityFeedProvider',
    () async {
      final txn = transaction();
      when(
        () => mockSettlement.createTransaction(
          receiverId: any(named: 'receiverId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          groupId: any(named: 'groupId'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => txn);

      when(() => mockFriends.fetchFriendBalance(receiverId))
          .thenAnswer((_) async => friendBalance());
      when(() => mockDashboard.fetchBalanceSummary())
          .thenAnswer((_) async => balanceSummary);
      when(
        () => mockDashboard.fetchActivity(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          groupId: any(named: 'groupId'),
        ),
      ).thenAnswer((_) async => []);

      await container.read(balanceSummaryProvider.future);
      await container.read(activityFeedProvider.future);
      await container.read(friendBalanceProvider(receiverId).future);

      await container.read(settleUpNotifierProvider.notifier).recordPayment(
            receiverId: receiverId,
            amount: '50.00',
            currency: 'BRL',
          );

      await container.read(balanceSummaryProvider.future);
      await container.read(activityFeedProvider.future);
      await container.read(friendBalanceProvider(receiverId).future);

      verify(
        () => mockSettlement.createTransaction(
          receiverId: receiverId,
          amount: '50.00',
          currency: 'BRL',
          groupId: null,
          note: null,
        ),
      ).called(1);
      verify(() => mockFriends.fetchFriendBalance(receiverId)).called(2);
      verify(() => mockDashboard.fetchBalanceSummary()).called(2);
      verify(
        () => mockDashboard.fetchActivity(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          groupId: any(named: 'groupId'),
        ),
      ).called(2);
      final settled = container.read(settleUpNotifierProvider);
      expect(settled, isA<AsyncData<TransactionModel?>>());
      expect((settled as AsyncData<TransactionModel?>).value, txn);
    },
  );

  test(
    'recordPayment with thrown ApiException sets state to AsyncError and rethrows',
    () async {
      when(
        () => mockSettlement.createTransaction(
          receiverId: any(named: 'receiverId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          groupId: any(named: 'groupId'),
          note: any(named: 'note'),
        ),
      ).thenAnswer(
        (_) => Future<TransactionModel>.error(
          const ApiException(statusCode: 400, message: 'bad'),
        ),
      );

      final sub = container.listen(settleUpNotifierProvider, (_, _) {});

      Object? caught;
      try {
        await container.read(settleUpNotifierProvider.notifier).recordPayment(
              receiverId: receiverId,
              amount: '50.00',
              currency: 'BRL',
            );
      } catch (e, _) {
        caught = e;
      }

      expect(caught, isA<ApiException>());
      expect(
        container.read(settleUpNotifierProvider),
        isA<AsyncError<TransactionModel?>>(),
      );
      final asyncErr =
          container.read(settleUpNotifierProvider) as AsyncError<TransactionModel?>;
      expect(asyncErr.error, isA<ApiException>());
      verify(
        () => mockSettlement.createTransaction(
          receiverId: receiverId,
          amount: '50.00',
          currency: 'BRL',
          groupId: null,
          note: null,
        ),
      ).called(1);
      sub.close();
    },
  );
}
