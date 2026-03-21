import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';

class MockUser extends Mock implements User {}

void main() {
  late MockUser authenticatedUser;

  setUp(() {
    authenticatedUser = MockUser();
  });

  group('computeRedirect', () {
    test('unauthenticated user at /dashboard redirects to /login', () {
      expect(
        computeRedirect(AuthState.unauthenticated(), '/dashboard'),
        '/login',
      );
    });

    test('unauthenticated user at /login returns null (no redirect)', () {
      expect(
        computeRedirect(AuthState.unauthenticated(), '/login'),
        isNull,
      );
    });

    test('authenticated user at /login redirects to /dashboard', () {
      expect(
        computeRedirect(
          AuthState.authenticated(user: authenticatedUser),
          '/login',
        ),
        '/dashboard',
      );
    });

    test('authenticated user at /dashboard returns null', () {
      expect(
        computeRedirect(
          AuthState.authenticated(user: authenticatedUser),
          '/dashboard',
        ),
        isNull,
      );
    });

    test('splash / with unauthenticated state redirects to /login', () {
      expect(
        computeRedirect(AuthState.unauthenticated(), '/'),
        '/login',
      );
    });

    test('splash / with authenticated state redirects to /dashboard', () {
      expect(
        computeRedirect(
          AuthState.authenticated(user: authenticatedUser),
          '/',
        ),
        '/dashboard',
      );
    });
  });

  group('appRouterProvider', () {
    test('router contains routes with paths /, /login, /dashboard', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      final paths = _collectGoRoutePaths(router.configuration.routes);

      expect(paths, containsAll(<String>['/', '/login', '/dashboard']));
    });
  });

  group('groupSettingsRouteRedirect', () {
    const gid = '11111111-1111-1111-1111-111111111111';
    const uid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    GroupDetailModel detailWithMemberRole(String role) {
      return GroupDetailModel.fromJson(<String, dynamic>{
        'id': gid,
        'name': 'G',
        'description': null,
        'type': 'trip',
        'currency': 'BRL',
        'simplify_debts': true,
        'created_by': uid,
        'members': <dynamic>[
          <String, dynamic>{
            'user_id': uid,
            'display_name': 'Current',
            'avatar_url': null,
            'role': role,
            'joined_at': '2025-03-01T09:00:00.000Z',
            'invited_by': null,
          },
        ],
        'net_balances': <dynamic>[],
        'created_at': '2025-03-01T08:00:00.000Z',
      });
    }

    test('null groupId allows navigation', () {
      expect(
        groupSettingsRouteRedirect(
          groupId: null,
          detailAsync: const AsyncLoading(),
          authState: null,
        ),
        isNull,
      );
    });

    test('loading detail redirects to group detail route', () {
      when(() => authenticatedUser.id).thenReturn(uid);
      expect(
        groupSettingsRouteRedirect(
          groupId: gid,
          detailAsync: const AsyncLoading(),
          authState: AuthState.authenticated(user: authenticatedUser),
        ),
        '/groups/$gid',
      );
    });

    test('error detail redirects to group detail route', () {
      when(() => authenticatedUser.id).thenReturn(uid);
      expect(
        groupSettingsRouteRedirect(
          groupId: gid,
          detailAsync: AsyncError(Exception('fail'), StackTrace.empty),
          authState: AuthState.authenticated(user: authenticatedUser),
        ),
        '/groups/$gid',
      );
    });

    test('MEMBER is redirected away from settings', () {
      when(() => authenticatedUser.id).thenReturn(uid);
      expect(
        groupSettingsRouteRedirect(
          groupId: gid,
          detailAsync: AsyncData(detailWithMemberRole('MEMBER')),
          authState: AuthState.authenticated(user: authenticatedUser),
        ),
        '/groups/$gid',
      );
    });

    test('ADMIN is not redirected', () {
      when(() => authenticatedUser.id).thenReturn(uid);
      expect(
        groupSettingsRouteRedirect(
          groupId: gid,
          detailAsync: AsyncData(detailWithMemberRole('ADMIN')),
          authState: AuthState.authenticated(user: authenticatedUser),
        ),
        isNull,
      );
    });
  });
}

/// Collects [GoRoute.path] values from a [RouteBase] tree.
List<String> _collectGoRoutePaths(List<RouteBase> routes) {
  final out = <String>[];
  void walk(List<RouteBase> list) {
    for (final route in list) {
      if (route is GoRoute) {
        out.add(route.path);
        walk(route.routes);
      } else if (route is ShellRoute) {
        walk(route.routes);
      } else if (route is StatefulShellRoute) {
        for (final branch in route.branches) {
          walk(branch.routes);
        }
      }
    }
  }

  walk(routes);
  return out;
}
