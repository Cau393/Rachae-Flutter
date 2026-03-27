// ignore_for_file: library_private_types_in_public_api

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/providers/group_members_provider.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';
import 'package:frontend/features/groups/providers/group_settings_notifier.dart';
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
  const gid = '11111111-1111-1111-1111-111111111111';

  setUpAll(() {
    registerFallbackValue('');
  });

  late _MockGroupRepository mockRepo;
  late ProviderContainer container;
  var leaveCalls = 0;

  setUp(() {
    mockRepo = _MockGroupRepository();
    leaveCalls = 0;
    container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(mockRepo),
        groupSettingsAfterLeaveProvider.overrideWithValue(() {
          leaveCalls++;
        }),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('deleteSelf calls deleteGroup once and invalidates list and detail', () async {
    when(() => mockRepo.fetchGroups()).thenAnswer((_) async => []);
    when(() => mockRepo.fetchGroupDetail(gid)).thenAnswer((_) async => _detail(gid));
    when(() => mockRepo.deleteGroup(gid)).thenAnswer((_) async {});

    final subList = container.listen(groupListProvider, (_, _) {});
    final subDetail = container.listen(groupDetailProvider(gid), (_, _) {});

    await container.read(groupListProvider.future);
    await container.read(groupDetailProvider(gid).future);

    await container.read(groupSettingsNotifierProvider(gid).notifier).deleteSelf();

    verify(() => mockRepo.deleteGroup(gid)).called(1);
    expect(leaveCalls, 1);

    await container.read(groupListProvider.future);
    await container.read(groupDetailProvider(gid).future);
    verify(() => mockRepo.fetchGroups()).called(2);
    verify(() => mockRepo.fetchGroupDetail(gid)).called(2);

    subList.close();
    subDetail.close();
  });

  test(
    'changeMemberRole invalidates members only — fetchGroupDetail count unchanged',
    () async {
      final member = GroupMemberModel.fromJson({
        'user_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'display_name': 'Bob',
        'avatar_url': null,
        'role': 'ADMIN',
        'joined_at': '2025-01-01T00:00:00.000Z',
        'invited_by': null,
      });
      when(() => mockRepo.fetchGroupDetail(gid)).thenAnswer((_) async => _detail(gid));
      when(() => mockRepo.fetchGroupMembers(gid)).thenAnswer((_) async => [member]);
      when(() => mockRepo.changeMemberRole(gid, any(), any()))
          .thenAnswer((_) async => member);

      final subDetail = container.listen(groupDetailProvider(gid), (_, _) {});
      final subMembers = container.listen(groupMembersProvider(gid), (_, _) {});
      final subSettings = container.listen(
        groupSettingsNotifierProvider(gid),
        (_, _) {},
      );

      await container.read(groupDetailProvider(gid).future);
      await container.read(groupMembersProvider(gid).future);

      await container
          .read(groupSettingsNotifierProvider(gid).notifier)
          .changeMemberRole('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'ADMIN');

      await container.read(groupMembersProvider(gid).future);
      verify(() => mockRepo.fetchGroupMembers(gid)).called(2);
      verify(() => mockRepo.fetchGroupDetail(gid)).called(1);

      subDetail.close();
      subMembers.close();
      subSettings.close();
    },
  );

  test('addMembersBatch calls addMember for each id and collects failures', () async {
    final member = GroupMemberModel.fromJson({
      'user_id': 'u1',
      'display_name': 'A',
      'avatar_url': null,
      'role': 'MEMBER',
      'joined_at': '2025-01-01T00:00:00.000Z',
      'invited_by': null,
    });
    when(() => mockRepo.addMember(gid, 'u1', 'MEMBER'))
        .thenAnswer((_) async => member);
    when(() => mockRepo.addMember(gid, 'u2', 'MEMBER')).thenAnswer(
      (_) => Future<GroupMemberModel>.error(
        const ApiException(statusCode: 400, message: 'bad'),
      ),
    );

    final result = await container
        .read(groupSettingsNotifierProvider(gid).notifier)
        .addMembersBatch(<String>['u1', 'u2']);

    expect(result.addedCount, 1);
    expect(result.failedUserIds, <String>['u2']);
    verify(() => mockRepo.addMember(gid, 'u1', 'MEMBER')).called(1);
    verify(() => mockRepo.addMember(gid, 'u2', 'MEMBER')).called(1);
  });

  test('repository error yields AsyncError without rethrowing from method', () async {
    when(() => mockRepo.changeMemberRole(gid, any(), any())).thenAnswer(
      (_) => Future<GroupMemberModel>.error(
        const ApiException(statusCode: 400, message: 'bad'),
      ),
    );

    final subSettings = container.listen(
      groupSettingsNotifierProvider(gid),
      (_, _) {},
    );
    await container
        .read(groupSettingsNotifierProvider(gid).notifier)
        .changeMemberRole('u', 'MEMBER');
    subSettings.close();

    final state = container.read(groupSettingsNotifierProvider(gid));
    expect(state, isA<AsyncError<void>>());
    expect((state as AsyncError<void>).error, isA<ApiException>());
  });
}
