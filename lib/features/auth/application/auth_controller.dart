import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/admin_auth_service.dart';
import '../data/auth_service.dart';
import '../data/auth_repository.dart';
import '../data/role_service.dart';
import '../domain/app_user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final roleServiceProvider = Provider<RoleService>((ref) => RoleService());

final adminAuthServiceProvider = Provider<AdminAuthService>(
  (ref) => AdminAuthService(
    authService: ref.watch(authServiceProvider),
    roleService: ref.watch(roleServiceProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(apiServiceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    authService: ref.watch(authServiceProvider),
    roleService: ref.watch(roleServiceProvider),
    adminAuthService: ref.watch(adminAuthServiceProvider),
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._repository) : super(const AsyncLoading()) {
    unawaited(restoreSession());
  }

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    try {
      final user = await _repository.restoreSession();
      state = AsyncData(user);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<AppUser> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AsyncData(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<AppUser?> adminLogin(String email, String password) async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(
      () => _repository.adminLogin(email: email, password: password),
    );
    state = nextState;
    return nextState.valueOrNull;
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      state = AsyncData(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<AppUser> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final user = await _repository.signInWithGoogle();
      state = AsyncData(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncData(null);
  }
}
