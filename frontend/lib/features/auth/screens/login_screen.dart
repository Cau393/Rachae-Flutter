import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/widgets/apple_sign_in_button.dart';
import 'package:frontend/features/auth/widgets/auth_loading_overlay.dart';
import 'package:frontend/features/auth/widgets/google_sign_in_button.dart';
import 'package:frontend/features/auth/widgets/rachae_logo.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Login with OAuth; local loading overlay during sign-in attempts.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const RachaeLogo(size: 72),
                      const SizedBox(height: 24),
                      Text(
                        l10n.loginTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 40),
                      if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS)
                        GoogleSignInButton(
                          isLoading: _isLoading,
                          onPressed: _handleGoogleSignIn,
                        )
                      else
                        Text(
                          l10n.unsupportedPlatformMessage,
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 12),
                      if (defaultTargetPlatform == TargetPlatform.iOS)
                        AppleSignInButton(
                          isLoading: _isLoading,
                          onPressed: _handleAppleSignIn,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            AuthLoadingOverlay(isVisible: _isLoading),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.oauthFailed)),
      );
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithApple();
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.oauthFailed)),
      );
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}
