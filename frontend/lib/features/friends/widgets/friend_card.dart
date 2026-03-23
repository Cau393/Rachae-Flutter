import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:frontend/features/friends/models/friend_model.dart';

const _kAvatarDiameter = 40.0;

class FriendCard extends StatelessWidget {
  const FriendCard({
    super.key,
    required this.model,
    required this.onTap,
  });

  final FriendModel model;
  final VoidCallback onTap;

  TextStyle _initialsStyle() =>
      const TextStyle(fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = model.avatarUrl?.trim();
    final hasAvatar = url != null && url.isNotEmpty;

    final Widget avatarChild = hasAvatar
        ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: url,
              width: _kAvatarDiameter,
              height: _kAvatarDiameter,
              fit: BoxFit.cover,
              placeholder: (context, _) => Center(
                child: Text(model.initials, style: _initialsStyle()),
              ),
              errorWidget: (context, url, err) => Center(
                child: Text(model.initials, style: _initialsStyle()),
              ),
            ),
          )
        : Text(model.initials, style: _initialsStyle());

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: _kAvatarDiameter / 2,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: avatarChild,
        ),
        title: Text(
          model.displayName,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          model.email,
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
