import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/widgets/expense_list_tile.dart';
import 'package:frontend/features/dashboard/widgets/settlement_list_tile.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class ActivityFeed extends ConsumerStatefulWidget {
  const ActivityFeed({
    super.key,
    this.groupId,
    this.linkedPrimaryScroll = false,
  });

  /// When set, loads `GET /ledger/activity/?group_id=…` via [groupActivityFeedProvider].
  final String? groupId;

  /// When true, the list uses the [NestedScrollView] body primary scroll controller (narrow
  /// dashboard). When false (e.g. wide layout inside [Row]), uses a dedicated [ScrollController].
  final bool linkedPrimaryScroll;

  @override
  ConsumerState<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends ConsumerState<ActivityFeed> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (!widget.linkedPrimaryScroll) {
      _scrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  void _maybeLoadMoreFromMetrics(ScrollMetrics m) {
    if (m.maxScrollExtent <= 0) return;
    if (m.pixels < m.maxScrollExtent * 0.85) return;
    final gid = widget.groupId;
    if (gid != null) {
      _groupFeedNotifier(gid).loadMore();
    } else {
      _globalFeedNotifier.loadMore();
    }
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (!n.metrics.hasContentDimensions) return false;
    if (n is ScrollUpdateNotification || n is OverscrollNotification) {
      _maybeLoadMoreFromMetrics(n.metrics);
    }
    return false;
  }

  ActivityFeedNotifier get _globalFeedNotifier =>
      ref.read(activityFeedProvider.notifier);

  GroupActivityFeedNotifier _groupFeedNotifier(String gid) =>
      ref.read(groupActivityFeedProvider(gid).notifier);

  void _tryAutoloadWhenListFitsViewport(List<ActivityItemModel> items) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (items.isEmpty) return;
      final pos = Scrollable.maybeOf(context)?.position;
      if (pos == null) return;
      if (pos.maxScrollExtent > 0) return;
      final gid = widget.groupId;
      if (gid != null) {
        final n = _groupFeedNotifier(gid);
        if (!n.hasMore || n.isLoadingMore) return;
        if (items.length % kActivityFeedPageSize != 0) return;
        n.loadMore();
      } else {
        final n = _globalFeedNotifier;
        if (!n.hasMore || n.isLoadingMore) return;
        if (items.length % kActivityFeedPageSize != 0) return;
        n.loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gid = widget.groupId;
    final provider = gid != null
        ? groupActivityFeedProvider(gid)
        : activityFeedProvider;
    final async = ref.watch(provider);

    ref.listen<AsyncValue<List<ActivityItemModel>>>(provider, (previous, next) {
      next.whenData(_tryAutoloadWhenListFitsViewport);
    });

    final body = async.map(
      data: (data) => _buildData(context, data.value),
      error: (e) => _buildError(context),
      loading: (l) {
        if (l.hasError) {
          return _buildError(context);
        }
        return ListView(
          primary: widget.linkedPrimaryScroll,
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      },
    );

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: body,
    );
  }

  Widget _buildData(BuildContext context, List<ActivityItemModel> items) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return ListView(
        primary: widget.linkedPrimaryScroll,
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(l10n.dashboardNoActivity)),
          ),
        ],
      );
    }

    final gid = widget.groupId;
    final bool showFooter;
    final bool loadingMore;
    final bool hasMore;
    if (gid != null) {
      final n = _groupFeedNotifier(gid);
      loadingMore = n.isLoadingMore;
      hasMore = n.hasMore;
      showFooter = loadingMore || (!hasMore && items.isNotEmpty);
    } else {
      final n = _globalFeedNotifier;
      loadingMore = n.isLoadingMore;
      hasMore = n.hasMore;
      showFooter = loadingMore || (!hasMore && items.isNotEmpty);
    }

    return ListView.builder(
      primary: widget.linkedPrimaryScroll,
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + (showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          if (loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                l10n.dashboardActivityEndOfList,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }
        final item = items[index];
        switch (item) {
          case final ExpenseActivity e:
            return ExpenseListTile(
              item: e,
              onTap: () => context.push('/expenses/${e.id}'),
            );
          case final TransactionActivity t:
            return SettlementListTile(item: t);
        }
      },
    );
  }

  Widget _buildError(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gid = widget.groupId;
    return ListView(
      primary: widget.linkedPrimaryScroll,
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.errorGeneric),
              TextButton(
                onPressed: () {
                  if (gid != null) {
                    ref.invalidate(groupActivityFeedProvider(gid));
                  } else {
                    ref.invalidate(activityFeedProvider);
                  }
                },
                child: Text(l10n.retryLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
