// Legacy demo screen. The signed-in home is DashboardScreen at /dashboard
// (AppShell + GoRouter). Pull-to-refresh and tab refresh live there.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../l10n/generated/app_localizations.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authController = ref.watch(authControllerProvider);
    final currentUser = authController.currentUser;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.homeTitle),
        actions: [
          TextButton(
            onPressed: () => ref.read(authControllerProvider).signOut(),
            child: Text(localizations.signOut),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.authenticatedMessage(currentUser?.email ?? ''),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(localizations.stageOneReady),
          ],
        ),
      ),
    );
  }
}
