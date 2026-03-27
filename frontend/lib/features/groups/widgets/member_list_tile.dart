import 'package:flutter/material.dart';

import 'package:frontend/core/l10n/role_l10n.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

const _kAvatarDiameter = 40.0;

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.member,
    required this.isCurrentUser,
    required this.canManage,
    this.canManageThisMember = true,
    required this.onChangeRole,
    required this.onRemove,
  });

  final GroupMemberModel member;
  final bool isCurrentUser;
  final bool canManage;

  /// When false, hides role/remove menu (e.g. non-creator admin must not manage the group creator).
  final bool canManageThisMember;
  final void Function(String role) onChangeRole;
  final VoidCallback onRemove;

  static String _initials(String displayName) {
    if (displayName.isEmpty) {
      return '?';
    }
    return displayName[0].toUpperCase();
  }

  static const List<String> _allRoles = <String>['ADMIN', 'MEMBER', 'VIEWER'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = isCurrentUser
        ? '${member.displayName} ${l10n.groupMemberCurrentUserSuffix}'
        : member.displayName;

    final initials = _initials(member.displayName);
    final url = member.avatarUrl;
    final hasUrl = url != null && url.trim().isNotEmpty;

    final Widget avatarChild = hasUrl
        ? Image.network(
            url,
            width: _kAvatarDiameter,
            height: _kAvatarDiameter,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Text(initials),
          )
        : Text(initials);

    final otherRoles =
        _allRoles.where((r) => r != member.role).toList(growable: false);

    return ListTile(
      leading: CircleAvatar(
        radius: _kAvatarDiameter / 2,
        child: avatarChild,
      ),
      title: Text(title),
      subtitle: Text(roleDisplayName(l10n, member.role)),
      trailing: canManage && canManageThisMember && !isCurrentUser
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') {
                  onRemove();
                } else {
                  onChangeRole(value);
                }
              },
              itemBuilder: (context) => [
                ...otherRoles.map(
                  (role) => PopupMenuItem<String>(
                    value: role,
                    child: Text(roleDisplayName(l10n, role)),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'remove',
                  child: Text(l10n.groupSettingsRemoveMember),
                ),
              ],
            )
          : null,
    );
  }
}
