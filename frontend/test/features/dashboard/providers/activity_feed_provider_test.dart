// ignore_for_file: library_private_types_in_public_api

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/repositories/dashboard_repository.dart';

class _MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late _MockDashboardRepository mockRepo;
  late ProviderContainer container;

  final createdAt = DateTime.utc(2024, 1, 1);

  ExpenseActivity expense(String id, {String amount = '10.00'}) {
    return ExpenseActivity(
      id: id,
      type: 'expense',
      groupId: null,
      groupName: null,
      amount: amount,
      currency: 'BRL',
      createdAt: createdAt,
      description: 'd-$id',
      paidById: 'user-$id',
      paidByName: 'Name-$id',
    );
  }

  setUp(() {
    mockRepo = _MockDashboardRepository();
    container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() => container.dispose());

  List<ActivityItemModel> pageOf20(String prefix) =>
      List.generate(kActivityFeedPageSize, (i) => expense('$prefix-$i'));

  group('build and loadMore', () {
    test('build sets AsyncData with page-1 results (2 items), hasMore false', () async {
      final p1a = expense('p1-a');
      final p1b = expense('p1-b');
      when(
        () => mockRepo.fetchActivity(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((invocation) async {
        final page = invocation.namedArguments[#page] as int? ?? 1;
        if (page == 1) {
          return [p1a, p1b];
        }
        return <ActivityItemModel>[];
      });

      await container.read(activityFeedProvider.future);
      final async = container.read(activityFeedProvider);
      expect(async, isA<AsyncData<List<ActivityItemModel>>>());
      expect(async.value, hasLength(2));
      expect(
        (container.read(activityFeedProvider.notifier))
            .hasMore,
        isFalse,
      );
    });

    test('after loadMore state merges page 2 (20 + 2 items)', () async {
      final p2a = expense('p2-a');
      final p2b = expense('p2-b');
      when(
        () => mockRepo.fetchActivity(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((invocation) async {
        final page = invocation.namedArguments[#page] as int? ?? 1;
        switch (page) {
          case 1:
            return pageOf20('p1');
          case 2:
            return [p2a, p2b];
          default:
            return <ActivityItemModel>[];
        }
      });

      await container.read(activityFeedProvider.future);
      await container.read(activityFeedProvider.notifier).loadMore();

      final list = container.read(activityFeedProvider).value!;
      expect(list, hasLength(kActivityFeedPageSize + 2));
      expect(list.last.id, 'p2-b');
    });
  });

  test(
    'page 3 empty then loadMore again does not call fetchActivity a fourth time',
    () async {
      var fetchCount = 0;
      when(
        () => mockRepo.fetchActivity(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((invocation) async {
        fetchCount++;
        final page = invocation.namedArguments[#page] as int? ?? 1;
        switch (page) {
          case 1:
            return pageOf20('p1');
          case 2:
            return pageOf20('p2');
          case 3:
            return <ActivityItemModel>[];
          default:
            return <ActivityItemModel>[];
        }
      });

      await container.read(activityFeedProvider.future);
      await container.read(activityFeedProvider.notifier).loadMore();
      await container.read(activityFeedProvider.notifier).loadMore();
      expect(fetchCount, 3);

      await container.read(activityFeedProvider.notifier).loadMore();
      expect(fetchCount, 3);
    },
  );

  test('refresh resets to page-1 items only', () async {
    when(
      () => mockRepo.fetchActivity(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int? ?? 1;
      if (page == 1) {
        return pageOf20('p1');
      }
      if (page == 2) {
        return pageOf20('p2');
      }
      return <ActivityItemModel>[];
    });

    await container.read(activityFeedProvider.future);
    await container.read(activityFeedProvider.notifier).loadMore();
    expect(
      container.read(activityFeedProvider).value,
      hasLength(kActivityFeedPageSize * 2),
    );

    await container.read(activityFeedProvider.notifier).refresh();

    final list = container.read(activityFeedProvider).value!;
    expect(list, hasLength(kActivityFeedPageSize));
    expect(list.first.id, 'p1-0');
  });

  test('deduplicates by id when page 2 overlaps page 1', () async {
    final p1a = expense('p1-a');
    final dup = expense('p1-a', amount: '99.00');
    final p2new = expense('p2-new');
    final page1 = <ActivityItemModel>[
      p1a,
      ...List.generate(19, (i) => expense('x-$i')),
    ];

    when(
      () => mockRepo.fetchActivity(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int? ?? 1;
      if (page == 1) {
        return page1;
      }
      if (page == 2) {
        return [dup, p2new];
      }
      return <ActivityItemModel>[];
    });

    await container.read(activityFeedProvider.future);
    await container.read(activityFeedProvider.notifier).loadMore();

    final list = container.read(activityFeedProvider).value!;
    expect(list, hasLength(kActivityFeedPageSize + 1));
    expect(list.map((e) => e.id).toList(), contains('p2-new'));
    expect(list.where((e) => e.id == 'p1-a'), hasLength(1));
    expect(list.firstWhere((e) => e.id == 'p1-a').amount, '10.00');
  });
}
