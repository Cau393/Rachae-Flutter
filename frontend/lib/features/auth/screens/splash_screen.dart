import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/widgets/rachae_logo.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Splash / auth bootstrap UI; navigation is handled by the router, not this widget.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RachaeLogo(size: 80),
            const SizedBox(height: 32),
            Semantics(
              label: AppLocalizations.of(context)!.splashLoading,
              child: const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
