import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/auth/invite_handoff.dart';
import 'package:frontend/features/auth/pending_friend_invite_token_provider.dart';
import 'package:frontend/features/auth/pending_friend_invite_token_storage.dart';
import 'package:frontend/features/auth/widgets/apple_sign_in_button.dart';
import 'package:frontend/features/auth/widgets/auth_loading_overlay.dart';
import 'package:frontend/features/auth/widgets/google_sign_in_button.dart';
import 'package:frontend/features/auth/widgets/rachae_logo.dart';
import 'package:frontend/features/friends/providers/friends_repository_provider.dart';
import 'package:frontend/src/config/app_config.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Login with OAuth; local loading overlay during sign-in attempts.
/// With `?invite_token=` (or `/invite?invite_token=`), stores the token and
/// POSTs accept after successful sign-in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _processingInvite = false;
  String? _lastSyncedInviteToken;
  bool _autoIosHandoffAttempted = false;

  String? _inviteTokenFromCurrentUrl() {
    final routerToken = GoRouter.maybeOf(
      context,
    )?.state.uri.queryParameters['invite_token']?.trim();
    if (routerToken != null && routerToken.isNotEmpty) {
      return routerToken;
    }
    final baseToken = Uri.base.queryParameters['invite_token']?.trim();
    if (baseToken != null && baseToken.isNotEmpty) {
      return baseToken;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeAutoTryIosHandoff(),
      );
    }
  }

  void _maybeAutoTryIosHandoff() {
    if (!mounted || _autoIosHandoffAttempted) return;
    if (!isMobileInviteHandoffBrowser()) return;
    final token = _inviteTokenFromCurrentUrl();
    if (token == null || token.isEmpty) return;
    _autoIosHandoffAttempted = true;
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      tryOpenInstalledIosAppForInvite(token);
    });
  }

  void _openInInstalledIosApp() {
    final uriToken = _inviteTokenFromCurrentUrl();
    final pending = ref.read(pendingFriendInviteTokenProvider);
    final token = (pending != null && pending.isNotEmpty) ? pending : uriToken;
    if (token != null && token.isNotEmpty) {
      tryOpenInstalledIosAppForInvite(token);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncInviteTokenFromRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_maybeAcceptFriendInvite());
    });
  }

  void _syncInviteTokenFromRoute() {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final token = router.state.uri.queryParameters['invite_token']?.trim();
    final baseToken = Uri.base.queryParameters['invite_token']?.trim();
    final storedToken = readPendingFriendInviteToken();
    final effectiveToken = (token != null && token.isNotEmpty)
        ? token
        : (baseToken != null && baseToken.isNotEmpty)
        ? baseToken
        : storedToken;
    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      if (_lastSyncedInviteToken == effectiveToken) {
        return;
      }
      _lastSyncedInviteToken = effectiveToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(pendingFriendInviteTokenProvider.notifier)
            .setToken(effectiveToken);
      });
    }
  }

  Future<void> _maybeAcceptFriendInvite() async {
    if (_processingInvite) return;
    final authAsync = ref.read(authNotifierProvider);
    final auth = authAsync.value;
    if (auth is! AuthStateAuthenticated) return;

    final router = GoRouter.maybeOf(context);
    final uriToken = _inviteTokenFromCurrentUrl();
    final pending = ref.read(pendingFriendInviteTokenProvider);
    final storedToken = readPendingFriendInviteToken();
    final token = (pending != null && pending.isNotEmpty)
        ? pending
        : (uriToken != null && uriToken.isNotEmpty)
        ? uriToken
        : storedToken;
    if (token == null || token.isEmpty) return;

    _processingInvite = true;
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(friendsRepositoryProvider).acceptInvite(token);
      ref.read(pendingFriendInviteTokenProvider.notifier).clear();
      clearPendingFriendInviteTokenStorage();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.friendAcceptSuccess)));
      router?.go('/friends');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    } finally {
      _processingInvite = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    ref.listen(authNotifierProvider, (previous, next) {
      next.whenData((auth) {
        if (auth is AuthStateAuthenticated) {
          unawaited(_maybeAcceptFriendInvite());
        }
      });
    });

    final hasInviteToken =
        (_inviteTokenFromCurrentUrl()?.isNotEmpty ?? false) ||
        (ref.watch(pendingFriendInviteTokenProvider)?.isNotEmpty ?? false);

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
                      if (kIsWeb && hasInviteToken) ...[
                        const SizedBox(height: 24),
                        if (isMobileInviteHandoffBrowser()) ...[
                          Text(
                            l10n.inviteOpenInAppHint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _openInInstalledIosApp,
                            child: Text(l10n.inviteOpenInAppButton),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          l10n.inviteGetTheAppHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => _openExternal(
                                AppConfig.iosAppStoreListingUrl,
                              ),
                              child: Text(l10n.inviteAppStoreButton),
                            ),
                            TextButton(
                              onPressed: () => _openExternal(
                                AppConfig.androidPlayStoreListingUrl,
                              ),
                              child: Text(l10n.invitePlayStoreButton),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 40),
                      if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS)
                        ..._buildSignInButtons()
                      else
                        Text(
                          l10n.unsupportedPlatformMessage,
                          textAlign: TextAlign.center,
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

  /// Sign-in buttons for the "supported" branch (web or iOS). On iOS, Apple
  /// is shown first per Apple HIG (Sign in with Apple must have equal or
  /// greater prominence than other third-party login options — Guideline 4.8).
  List<Widget> _buildSignInButtons() {
    final apple = AppleSignInButton(
      isLoading: _isLoading,
      onPressed: _handleAppleSignIn,
    );
    final google = GoogleSignInButton(
      isLoading: _isLoading,
      onPressed: _handleGoogleSignIn,
    );
    final spacer = const SizedBox(height: 12);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return [apple, spacer, google];
    }
    return [google, spacer, apple];
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final uriToken = _inviteTokenFromCurrentUrl();
      final pending = ref.read(pendingFriendInviteTokenProvider);
      final token = (pending != null && pending.isNotEmpty)
          ? pending
          : uriToken;
      await ref
          .read(authNotifierProvider.notifier)
          .signInWithGoogle(inviteToken: token);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.oauthFailed)));
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final uriToken = _inviteTokenFromCurrentUrl();
      final pending = ref.read(pendingFriendInviteTokenProvider);
      final token = (pending != null && pending.isNotEmpty)
          ? pending
          : uriToken;
      await ref
          .read(authNotifierProvider.notifier)
          .signInWithApple(inviteToken: token);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.oauthFailed)));
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}
