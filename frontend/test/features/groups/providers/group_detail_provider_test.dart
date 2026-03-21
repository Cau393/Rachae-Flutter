// ignore_for_file: library_private_types_in_public_api

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';
import 'package:frontend/features/groups/repositories/group_repository.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

GroupDetailModel _detail(String id) => GroupDetailModel.fromJson({
      'id': id,
      'name': 'G',
      'description': null,
      'type': 'home',
      'currency': 'BRL',
      'simplify_debts': true,
      'created_by': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'members': <dynamic>[],
      'net_balances': <dynamic>[],
      'created_at': '2025-01-01T00:00:00.000Z',
    });

void main() {
  const idA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const idB = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  late _MockGroupRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = _MockGroupRepository();
    container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() => container.dispose());

  test(
    'groupDetailProvider(idA) and groupDetailProvider(idB) are independent',
    () async {
      when(() => mockRepo.fetchGroupDetail(idA)).thenAnswer((_) async => _detail(idA));
      when(() => mockRepo.fetchGroupDetail(idB)).thenAnswer((_) async => _detail(idB));

      final subA = container.listen(groupDetailProvider(idA), (_, _) {});
      final subB = container.listen(groupDetailProvider(idB), (_, _) {});

      final a = await container.read(groupDetailProvider(idA).future);
      final b = await container.read(groupDetailProvider(idB).future);
      expect(a.id, idA);
      expect(b.id, idB);

      container.invalidate(groupDetailProvider(idA));
      await container.read(groupDetailProvider(idA).future);
      await container.read(groupDetailProvider(idB).future);

      verify(() => mockRepo.fetchGroupDetail(idA)).called(2);
      verify(() => mockRepo.fetchGroupDetail(idB)).called(1);

      subA.close();
      subB.close();
    },
  );
}
