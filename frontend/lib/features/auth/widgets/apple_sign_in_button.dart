import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Presentational Apple OAuth sign-in button (full-width, l10n label, loading state).
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({super.key, this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      label: l10n.signInWithApple,
      child: SizedBox(
        width: double.infinity,
        // Avoid duplicate semantics labels (outer [Semantics] + [FilledButton] merge).
        child: ExcludeSemantics(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : SvgPicture.asset(
                    'assets/branding/apple.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
            label: isLoading ? const Text('') : Text(l10n.signInWithApple),
          ),
        ),
      ),
    );
  }
}
