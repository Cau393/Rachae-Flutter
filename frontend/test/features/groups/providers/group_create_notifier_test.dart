// ignore_for_file: library_private_types_in_public_api

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/providers/group_create_notifier.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';
import 'package:frontend/features/groups/repositories/group_repository.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

GroupDetailModel _newGroup(String id) => GroupDetailModel.fromJson({
      'id': id,
      'name': 'New',
      'description': null,
      'type': 'other',
      'currency': 'BRL',
      'simplify_debts': true,
      'created_by': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'members': <dynamic>[],
      'net_balances': <dynamic>[],
      'created_at': '2025-01-01T00:00:00.000Z',
    });

void main() {
  const newId = '99999999-9999-9999-9999-999999999999';

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late _MockGroupRepository mockRepo;
  late ProviderContainer container;
  String? onSuccessId;

  setUp(() {
    mockRepo = _MockGroupRepository();
    onSuccessId = null;
    container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(mockRepo),
        groupCreateOnSuccessProvider.overrideWithValue((id) {
          onSuccessId = id;
        }),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('submit calls createGroup once and invalidates groupListProvider', () async {
    when(() => mockRepo.fetchGroups()).thenAnswer((_) async => []);
    when(() => mockRepo.createGroup(any())).thenAnswer((_) async => _newGroup(newId));

    await container.read(groupListProvider.future);

    await container
        .read(groupCreateNotifierProvider.notifier)
        .submit({'name': 'New'});

    verify(() => mockRepo.createGroup(any())).called(1);
    await container.read(groupListProvider.future);
    verify(() => mockRepo.fetchGroups()).called(2);
  });

  test('submit invokes onSuccess with new group id', () async {
    when(() => mockRepo.fetchGroups()).thenAnswer((_) async => []);
    when(() => mockRepo.createGroup(any())).thenAnswer((_) async => _newGroup(newId));

    await container.read(groupListProvider.future);

    await container
        .read(groupCreateNotifierProvider.notifier)
        .submit({'name': 'New'});

    expect(onSuccessId, newId);
  });
}
