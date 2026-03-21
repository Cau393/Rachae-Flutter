import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Presentational Google OAuth sign-in button (full-width, l10n label, loading state).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = AppTheme.light.colorScheme;

    return Semantics(
      button: true,
      label: l10n.signInWithGoogle,
      child: SizedBox(
        width: double.infinity,
        // Avoid duplicate semantics labels (outer [Semantics] + [FilledButton] merge).
        child: ExcludeSemantics(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : SvgPicture.asset(
                    'assets/branding/google.svg',
                    width: 24,
                    height: 24,
                  ),
            label: isLoading ? const Text('') : Text(l10n.signInWithGoogle),
          ),
        ),
      ),
    );
  }
}
