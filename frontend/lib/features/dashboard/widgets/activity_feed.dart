import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/widgets/expense_list_tile.dart';
import 'package:frontend/features/dashboard/widgets/settlement_list_tile.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class ActivityFeed extends ConsumerStatefulWidget {
  const ActivityFeed({super.key, this.groupId});

  /// When set, loads `GET /ledger/activity/?group_id=…` via [groupActivityFeedProvider].
  final String? groupId;

  @override
  ConsumerState<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends ConsumerState<ActivityFeed> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels >= pos.maxScrollExtent * 0.85) {
      final gid = widget.groupId;
      if (gid != null) {
        ref.read(groupActivityFeedProvider(gid).notifier).loadMore();
      } else {
        ref.read(activityFeedProvider.notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gid = widget.groupId;
    final async = gid != null
        ? ref.watch(groupActivityFeedProvider(gid))
        : ref.watch(activityFeedProvider);

    return async.map(
      data: (data) => _buildData(context, data.value),
      error: (e) => _buildError(context),
      loading: (l) {
        if (l.hasError) {
          return _buildError(context);
        }
        return ListView(
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
  }

  Widget _buildData(BuildContext context, List<ActivityItemModel> items) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return ListView(
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

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        switch (item) {
          case final ExpenseActivity e:
            return ExpenseListTile(item: e);
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
