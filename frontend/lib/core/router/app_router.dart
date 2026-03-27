import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/auth/screens/splash_screen.dart';
import 'package:frontend/features/dashboard/screens/dashboard_screen.dart';
import 'package:frontend/features/dashboard/screens/owed_to_me_expenses_screen.dart';
import 'package:frontend/features/dashboard/screens/pending_approvals_screen.dart';
import 'package:frontend/features/dashboard/screens/pending_settlements_screen.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/screens/create_group_screen.dart';
import 'package:frontend/features/groups/screens/group_detail_screen.dart';
import 'package:frontend/features/groups/screens/group_list_screen.dart';
import 'package:frontend/features/expenses/screens/add_expense_screen.dart';
import 'package:frontend/features/expenses/screens/expense_detail_screen.dart';
import 'package:frontend/features/groups/screens/group_add_members_screen.dart';
import 'package:frontend/features/groups/screens/group_settings_screen.dart';
import 'package:frontend/features/profile/providers/profile_notifier.dart';
import 'package:frontend/features/friends/screens/friend_detail_screen.dart';
import 'package:frontend/features/friends/screens/friends_screen.dart';
import 'package:frontend/features/settlements/screens/settle_up_screen.dart';
import 'package:frontend/features/profile/screens/export_screen.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/features/shell/app_shell.dart';

/// Pure, testable redirect function.
String? computeRedirect(AuthState authState, Uri uri) {
  final location = uri.path;
  final hasInviteToken = (uri.queryParameters['invite_token'] ?? '').trim().isNotEmpty;
  final isAuthenticated = authState.isAuthenticated;
  String? redirect;
  if (location == '/') {
    redirect = isAuthenticated ? '/dashboard' : '/login';
  } else if (!isAuthenticated && location != '/login') {
    redirect = '/login';
  } else if (isAuthenticated && location == '/login' && !hasInviteToken) {
    redirect = '/dashboard';
  }
  return redirect;
}

/// ADMIN-only guard for `/groups/:groupId/settings` (pure logic for tests).
///
/// When [detailAsync] has no data yet, returns `/groups/[groupId]` so the user
/// lands on the detail screen until cache is warm.
String? groupSettingsRouteRedirect({
  required String? groupId,
  required AsyncValue<GroupDetailModel> detailAsync,
  required AuthState? authState,
}) {
  if (groupId == null || groupId.isEmpty) return null;

  return detailAsync.when(
    data: (detail) {
      final userId = switch (authState) {
        AuthStateAuthenticated(:final user) => user.id,
        _ => '',
      };
      final role = detail.memberByUserId(userId)?.role ?? 'VIEWER';
      return role == 'ADMIN' ? null : '/groups/$groupId';
    },
    loading: () => '/groups/$groupId',
    error: (_, _) => '/groups/$groupId',
  );
}

/// ADMIN-only guard for `/groups/:groupId/add-members`.
///
/// While [detailAsync] is loading or in error, returns `null` so the route can
/// open (avoids bouncing back to group detail when cache is cold). When detail
/// is ready, uses [currentUserId] (Django user id preferred — same as
/// [GroupDetailScreen]) to resolve role; empty [currentUserId] allows navigation
/// and [GroupAddMembersScreen] enforces access after profile loads.
String? groupAddMembersRouteRedirect({
  required String? groupId,
  required AsyncValue<GroupDetailModel> detailAsync,
  required String currentUserId,
}) {
  if (groupId == null || groupId.isEmpty) return null;

  return detailAsync.when(
    data: (detail) {
      if (currentUserId.isEmpty) return null;
      final role = detail.memberByUserId(currentUserId)?.role ?? 'VIEWER';
      return role == 'ADMIN' ? null : '/groups/$groupId';
    },
    loading: () => null,
    error: (_, _) => null,
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/invite',
        redirect: (context, state) {
          final uri = state.uri;
          if (!uri.hasQuery) {
            return '/login';
          }
          return Uri(
            path: '/login',
            queryParameters: uri.queryParameters,
          ).toString();
        },
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/expenses/new',
        builder: (_, _) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: '/expenses/:id',
        builder: (context, state) => ExpenseDetailScreen(
          expenseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/friends/:id',
        builder: (context, state) => FriendDetailScreen(
          friendId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/settle',
        builder: (context, state) => const SettleUpScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          currentIndex: navigationShell.currentIndex,
          child: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'pending-approvals',
                    builder: (_, _) => const PendingApprovalsScreen(),
                  ),
                  GoRoute(
                    path: 'owed-to-me',
                    builder: (_, _) => const OwedToMeExpensesScreen(),
                  ),
                  GoRoute(
                    path: 'pending-settlements',
                    builder: (_, _) => const PendingSettlementsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/groups',
                builder: (_, _) => const GroupListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const CreateGroupScreen(),
                  ),
                  GoRoute(
                    path: ':groupId',
                    builder: (context, state) => GroupDetailScreen(
                      groupId: state.pathParameters['groupId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'add-members',
                        redirect: (context, state) {
                          final groupId = state.pathParameters['groupId'];
                          if (groupId == null) return null;
                          final djangoId = ref
                              .read(profileNotifierProvider)
                              .maybeWhen(
                                data: (p) => p.id,
                                orElse: () => '',
                              );
                          final supabaseUid = ref
                              .read(authNotifierProvider)
                              .maybeWhen(
                                data: (s) => switch (s) {
                                  AuthStateAuthenticated(:final user) =>
                                    user.id,
                                  _ => '',
                                },
                                orElse: () => '',
                              );
                          final currentUserId =
                              djangoId.isNotEmpty ? djangoId : supabaseUid;
                          return groupAddMembersRouteRedirect(
                            groupId: groupId,
                            detailAsync:
                                ref.read(groupDetailProvider(groupId)),
                            currentUserId: currentUserId,
                          );
                        },
                        builder: (context, state) => GroupAddMembersScreen(
                          groupId: state.pathParameters['groupId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'settings',
                        redirect: (context, state) {
                          final groupId = state.pathParameters['groupId'];
                          if (groupId == null) return null;
                          return groupSettingsRouteRedirect(
                            groupId: groupId,
                            detailAsync:
                                ref.read(groupDetailProvider(groupId)),
                            authState:
                                ref.read(authNotifierProvider).value,
                          );
                        },
                        builder: (context, state) => GroupSettingsScreen(
                          groupId: state.pathParameters['groupId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/friends',
                builder: (_, _) => const FriendsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'export',
                    builder: (_, _) => const ExportScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final current = authState.value ?? const AuthState.initial();
      return computeRedirect(current, state.uri);
    },
  );
});
