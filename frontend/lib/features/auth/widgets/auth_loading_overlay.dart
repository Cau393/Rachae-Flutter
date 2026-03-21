import 'package:flutter/material.dart';

import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Full-screen loading barrier during async auth / OAuth handoff.
class AuthLoadingOverlay extends StatelessWidget {
  const AuthLoadingOverlay({super.key, required this.isVisible});

  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      liveRegion: true,
      label: l10n.loadingLabel,
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
