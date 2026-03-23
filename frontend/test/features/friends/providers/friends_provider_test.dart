// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/friends/providers/friends_repository_provider.dart';
import 'package:frontend/features/friends/repositories/friends_repository.dart';

class _MockFriendsRepository extends Mock implements FriendsRepository {}

void main() {
  late _MockFriendsRepository mockRepo;
  late ProviderContainer container;

  final sampleFriends = [
    FriendModel.fromJson(<String, dynamic>{
      'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'display_name': 'Alice',
      'email': 'a@x.com',
      'phone': null,
      'avatar_url': null,
    }),
  ];

  setUp(() {
    mockRepo = _MockFriendsRepository();
    container = ProviderContainer(
      overrides: [friendsRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() => container.dispose());

  test('initial state is AsyncLoading while fetch is pending', () {
    final completer = Completer<List<FriendModel>>();
    when(() => mockRepo.fetchFriends()).thenAnswer((_) => completer.future);

    final state = container.read(friendsProvider);
    expect(state, isA<AsyncLoading<List<FriendModel>>>());
  });

  test('after mock resolves, state is AsyncData<List<FriendModel>>', () async {
    when(() => mockRepo.fetchFriends()).thenAnswer((_) async => sampleFriends);

    final list = await container.read(friendsProvider.future);
    expect(list, sampleFriends);
    expect(container.read(friendsProvider), isA<AsyncData<List<FriendModel>>>());
    expect(container.read(friendsProvider).value, sampleFriends);
  });
}
