import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:frontend/features/profile/providers/profile_notifier.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class AvatarEditor extends ConsumerStatefulWidget {
  const AvatarEditor({super.key});

  @override
  ConsumerState<AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends ConsumerState<AvatarEditor> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (xfile == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    setState(() => _uploading = true);
    try {
      final file = File(xfile.path);
      final success =
          await ref.read(profileNotifierProvider.notifier).uploadAvatar(file);
      if (!success && mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.profileAvatarUploadError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileNotifierProvider);

    return profileAsync.when(
      data: (profile) {
        final url = profile.avatarUrl;
        final hasHttp = url != null && url.startsWith('http');
        return Semantics(
          button: true,
          label: l10n.profileAvatarChangeButton,
          child: InkWell(
            onTap: _uploading ? null : _pickAndUpload,
            customBorder: const CircleBorder(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      hasHttp ? NetworkImage(url) : null,
                  child: hasHttp
                      ? null
                      : Text(
                          profile.initials,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                ),
                if (_uploading)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const CircleAvatar(
        radius: 40,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => const CircleAvatar(
        radius: 40,
        child: Icon(Icons.error_outline),
      ),
    );
  }
}
