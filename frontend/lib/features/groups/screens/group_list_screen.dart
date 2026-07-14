import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/widgets/group_card.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

extension GroupListScreenL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.groupsTitle),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_group_list_create',
        onPressed: () => context.go('/groups/new'),
        tooltip: context.l10n.groupsCreateFab,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(groupListProvider);
                await ref.read(groupListProvider.future);
              },
              child: groupsAsync.when(
                loading: () => _scrollableCentered(
                  child: const CircularProgressIndicator(),
                ),
                error: (Object e, StackTrace st) => _scrollableCentered(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.l10n.errorGeneric),
                      TextButton(
                        onPressed: () => ref.invalidate(groupListProvider),
                        child: Text(context.l10n.retryLabel),
                      ),
                    ],
                  ),
                ),
                data: (List<GroupSummaryModel> groups) {
                  if (groups.isEmpty) {
                    return _scrollableCentered(
                      child: Text(context.l10n.groupsEmpty),
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: groups.length,
                    itemBuilder: (BuildContext context, int i) {
                      final g = groups[i];
                      return GroupCard(
                        model: g,
                        onTap: () => context.go('/groups/${g.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Keeps [RefreshIndicator] usable when content is short (loading, error, empty).
  Widget _scrollableCentered({required Widget child}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
