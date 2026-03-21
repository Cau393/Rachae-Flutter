import 'package:supabase_flutter/supabase_flutter.dart';

/// App auth state (distinct from gotrue's [AuthState] stream type).
sealed class AuthState {
  const AuthState();

  bool get isAuthenticated => this is AuthStateAuthenticated;

  const factory AuthState.initial() = AuthStateInitial;
  const factory AuthState.loading() = AuthStateLoading;
  const factory AuthState.authenticated({required User user}) =
      AuthStateAuthenticated;
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;
}

final class AuthStateInitial extends AuthState {
  const AuthStateInitial();

  @override
  bool operator ==(Object other) => other is AuthStateInitial;

  @override
  int get hashCode => 1;
}

final class AuthStateLoading extends AuthState {
  const AuthStateLoading();

  @override
  bool operator ==(Object other) => other is AuthStateLoading;

  @override
  int get hashCode => 2;
}

final class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated({required this.user});

  final User user;

  @override
  bool operator ==(Object other) =>
      other is AuthStateAuthenticated && other.user == user;

  @override
  int get hashCode => Object.hash(AuthStateAuthenticated, user);
}

final class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();

  @override
  bool operator ==(Object other) => other is AuthStateUnauthenticated;

  @override
  int get hashCode => 3;
}
