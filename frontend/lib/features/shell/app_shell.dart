import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/widgets/ad_banner.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  /// Tab order: dashboard, groups, friends, profile.
  static const List<String> tabRoutes = [
    '/dashboard',
    '/groups',
    '/friends',
    '/profile',
  ];

  final Widget child;
  final int currentIndex;

  void _goToTab(BuildContext context, int index) {
    context.go(tabRoutes[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;

        if (wide) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (i) => _goToTab(context, i),
                  labelType: NavigationRailLabelType.all,
                  trailing: const SizedBox(
                    width: 72,
                    child: AdBanner(),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.home),
                      label: Text(l10n.navDashboard),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.group),
                      label: Text(l10n.navGroups),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.people),
                      label: Text(l10n.navFriends),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person),
                      label: Text(l10n.navProfile),
                    ),
                  ],
                ),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              Expanded(child: child),
              const AdBanner(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (i) => _goToTab(context, i),
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: l10n.navDashboard,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.group),
                label: l10n.navGroups,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people),
                label: l10n.navFriends,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: l10n.navProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}
