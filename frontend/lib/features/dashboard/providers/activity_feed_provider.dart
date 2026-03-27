import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';

/// Page size for [ActivityFeedNotifier] and [GroupActivityFeedNotifier].
const int kActivityFeedPageSize = 20;

final activityFeedProvider =
    AsyncNotifierProvider<ActivityFeedNotifier, List<ActivityItemModel>>(
      ActivityFeedNotifier.new,
    );

final groupActivityFeedProvider = AsyncNotifierProvider.autoDispose
    .family<GroupActivityFeedNotifier, List<ActivityItemModel>, String>(
  GroupActivityFeedNotifier.new,
);

List<ActivityItemModel> mergeActivityDedupe(
  List<ActivityItemModel> base,
  List<ActivityItemModel> incoming,
) {
  final ids = base.map((e) => e.id).toSet();
  final out = [...base];
  for (final item in incoming) {
    if (ids.add(item.id)) {
      out.add(item);
    }
  }
  return out;
}

class ActivityFeedNotifier extends AsyncNotifier<List<ActivityItemModel>> {
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  @override
  Future<List<ActivityItemModel>> build() async {
    _currentPage = 1;
    _hasMore = true;
    _loadingMore = false;
    final repo = ref.watch(dashboardRepositoryProvider);
    final list = await repo.fetchActivity(page: 1, limit: kActivityFeedPageSize);
    _hasMore = list.length >= kActivityFeedPageSize;
    return list;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    final current = state.value;
    if (current == null) return;

    _loadingMore = true;
    try {
      final repo = ref.read(dashboardRepositoryProvider);
      _currentPage++;
      final more =
          await repo.fetchActivity(page: _currentPage, limit: kActivityFeedPageSize);
      if (more.isEmpty) {
        _hasMore = false;
        return;
      }
      state = AsyncData(mergeActivityDedupe(current, more));
      if (more.length < kActivityFeedPageSize) {
        _hasMore = false;
      }
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    _loadingMore = false;
    _currentPage = 1;
    _hasMore = true;
    state = const AsyncLoading<List<ActivityItemModel>>();
    final repo = ref.read(dashboardRepositoryProvider);
    final list = await repo.fetchActivity(page: 1, limit: kActivityFeedPageSize);
    _hasMore = list.length >= kActivityFeedPageSize;
    state = AsyncData(list);
  }
}

class GroupActivityFeedNotifier extends AsyncNotifier<List<ActivityItemModel>> {
  GroupActivityFeedNotifier(this.groupId);

  final String groupId;

  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  @override
  Future<List<ActivityItemModel>> build() async {
    _currentPage = 1;
    _hasMore = true;
    _loadingMore = false;
    final repo = ref.watch(dashboardRepositoryProvider);
    final list = await repo.fetchActivity(
      page: 1,
      limit: kActivityFeedPageSize,
      groupId: groupId,
    );
    _hasMore = list.length >= kActivityFeedPageSize;
    return list;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    final current = state.value;
    if (current == null) return;

    _loadingMore = true;
    try {
      final repo = ref.read(dashboardRepositoryProvider);
      _currentPage++;
      final more = await repo.fetchActivity(
        page: _currentPage,
        limit: kActivityFeedPageSize,
        groupId: groupId,
      );
      if (more.isEmpty) {
        _hasMore = false;
        return;
      }
      state = AsyncData(mergeActivityDedupe(current, more));
      if (more.length < kActivityFeedPageSize) {
        _hasMore = false;
      }
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    _loadingMore = false;
    _currentPage = 1;
    _hasMore = true;
    state = const AsyncLoading<List<ActivityItemModel>>();
    final repo = ref.read(dashboardRepositoryProvider);
    final list = await repo.fetchActivity(
      page: 1,
      limit: kActivityFeedPageSize,
      groupId: groupId,
    );
    _hasMore = list.length >= kActivityFeedPageSize;
    state = AsyncData(list);
  }
}
