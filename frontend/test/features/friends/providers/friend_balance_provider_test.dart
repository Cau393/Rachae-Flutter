// ignore_for_file: library_private_types_in_public_api

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/friends/models/friend_balance_model.dart';
import 'package:frontend/features/friends/providers/friend_balance_provider.dart';
import 'package:frontend/features/friends/providers/friends_repository_provider.dart';
import 'package:frontend/features/friends/repositories/friends_repository.dart';

class _MockFriendsRepository extends Mock implements FriendsRepository {}

void main() {
  const userA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const userB = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  late _MockFriendsRepository mockRepo;
  late ProviderContainer container;

  FriendBalanceModel balanceFor(String id) => FriendBalanceModel.fromJson(<String, dynamic>{
        'balance': id == userA ? '10.00' : '-5.00',
        'currency': 'BRL',
      });

  setUp(() {
    mockRepo = _MockFriendsRepository();
    container = ProviderContainer(
      overrides: [friendsRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() => container.dispose());

  test(
    'friendBalanceProvider(userA) and friendBalanceProvider(userB) are independent',
    () async {
      when(() => mockRepo.fetchFriendBalance(userA))
          .thenAnswer((_) async => balanceFor(userA));
      when(() => mockRepo.fetchFriendBalance(userB))
          .thenAnswer((_) async => balanceFor(userB));

      final subA = container.listen(friendBalanceProvider(userA), (_, _) {});
      final subB = container.listen(friendBalanceProvider(userB), (_, _) {});

      final a = await container.read(friendBalanceProvider(userA).future);
      final b = await container.read(friendBalanceProvider(userB).future);
      expect(a.balance, '10.00');
      expect(b.balance, '-5.00');

      container.invalidate(friendBalanceProvider(userA));
      await container.read(friendBalanceProvider(userA).future);
      await container.read(friendBalanceProvider(userB).future);

      verify(() => mockRepo.fetchFriendBalance(userA)).called(2);
      verify(() => mockRepo.fetchFriendBalance(userB)).called(1);

      subA.close();
      subB.close();
    },
  );
}
