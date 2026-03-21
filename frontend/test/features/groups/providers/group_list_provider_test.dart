// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';
import 'package:frontend/features/groups/repositories/group_repository.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late _MockGroupRepository mockRepo;
  late ProviderContainer container;

  final sampleList = [
    GroupSummaryModel.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'name': 'A',
      'type': 'trip',
      'currency': 'BRL',
      'member_count': 2,
      'your_net_balance': '0.00',
      'created_at': '2025-01-01T00:00:00.000Z',
    }),
  ];

  setUp(() {
    mockRepo = _MockGroupRepository();
    container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() => container.dispose());

  test('initial state is AsyncLoading while fetch is pending', () {
    final completer = Completer<List<GroupSummaryModel>>();
    when(() => mockRepo.fetchGroups()).thenAnswer((_) => completer.future);

    final state = container.read(groupListProvider);
    expect(state, isA<AsyncLoading<List<GroupSummaryModel>>>());
  });

  test('after resolve, state is AsyncData with the list', () async {
    when(() => mockRepo.fetchGroups()).thenAnswer((_) async => sampleList);

    final list = await container.read(groupListProvider.future);
    expect(list, sampleList);
    expect(container.read(groupListProvider).value, sampleList);
  });

  test('invalidate triggers a second fetchGroups', () async {
    when(() => mockRepo.fetchGroups()).thenAnswer((_) async => sampleList);

    await container.read(groupListProvider.future);
    container.invalidate(groupListProvider);
    await container.read(groupListProvider.future);

    verify(() => mockRepo.fetchGroups()).called(2);
  });
}
