import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/friends/widgets/friend_card.dart';
import 'package:frontend/features/friends/widgets/friend_invite_sheet.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  String _searchQuery = '';

  List<FriendModel> _filtered(List<FriendModel> friends) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return friends;
    }
    return friends
        .where(
          (f) =>
              f.displayName.toLowerCase().contains(q) ||
              f.email.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(friendsProvider);
    await ref.read(friendsProvider.future);
    if (!mounted) {
      return;
    }
  }

  void _openInviteSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const FriendInviteSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.friendsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _openInviteSheet,
            tooltip: l10n.friendsInviteButton,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SearchBar(
              hintText: l10n.friendsSearchHint,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: friendsAsync.when(
                loading: () => _scrollableCentered(
                  child: const CircularProgressIndicator(),
                ),
                error: (Object e, StackTrace st) => _scrollableCentered(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.errorGeneric),
                      TextButton(
                        onPressed: () => ref.invalidate(friendsProvider),
                        child: Text(l10n.retryLabel),
                      ),
                    ],
                  ),
                ),
                data: (List<FriendModel> friends) {
                  if (friends.isEmpty) {
                    return _scrollableCentered(
                      child: Text(
                        l10n.friendsEmpty,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final filtered = _filtered(friends);
                  if (filtered.isEmpty) {
                    return _scrollableCentered(
                      child: Text(
                        l10n.noResultsLabel,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (BuildContext context, int i) {
                      final f = filtered[i];
                      return FriendCard(
                        model: f,
                        onTap: () => context.push('/friends/${f.id}'),
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
