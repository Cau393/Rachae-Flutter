import 'package:flutter/material.dart';

import 'package:frontend/core/l10n/group_type_l10n.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class GroupHeader extends StatelessWidget {
  const GroupHeader({super.key, required this.model});

  final GroupDetailModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    model.name,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                Chip(
                  label: Text(model.currency),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              groupTypeDisplayName(l10n, model.type),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _AvatarStack(members: model.members),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members});

  final List<GroupMemberModel> members;

  static const double _avatarDiameter = 40;
  static const double _step = 30;

  String _initials(String displayName) {
    if (displayName.isEmpty) {
      return '?';
    }
    return displayName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = members.take(5).toList();
    final overflowCount = members.length - visible.length;
    final slotCount = visible.length + (overflowCount > 0 ? 1 : 0);
    final width = _step * (slotCount - 1) + _avatarDiameter;

    return SizedBox(
      height: _avatarDiameter,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * _step,
              top: 0,
              child: _MemberAvatar(
                member: visible[i],
                initials: _initials(visible[i].displayName),
              ),
            ),
          if (overflowCount > 0)
            Positioned(
              left: visible.length * _step,
              top: 0,
              child: CircleAvatar(
                radius: _avatarDiameter / 2,
                child: Text('+$overflowCount'),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.member,
    required this.initials,
  });

  final GroupMemberModel member;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final url = member.avatarUrl;
    final hasUrl = url != null && url.isNotEmpty;

    final Widget avatarChild = hasUrl
        ? Image.network(
            url,
            width: _AvatarStack._avatarDiameter,
            height: _AvatarStack._avatarDiameter,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Text(initials),
          )
        : Text(initials);

    return Tooltip(
      message: member.displayName,
      child: CircleAvatar(
        radius: _AvatarStack._avatarDiameter / 2,
        child: avatarChild,
      ),
    );
  }
}
