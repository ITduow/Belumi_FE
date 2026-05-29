import 'dart:async';

import '../../../core/network/dio_api_service.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/app_user.dart';
import 'admin_auth_service.dart';
import 'auth_service.dart';
import 'role_service.dart';

class AuthRepository {
  AuthRepository({
    required DioApiService api,
    required TokenStorage tokenStorage,
    required AuthService authService,
    required RoleService roleService,
    required AdminAuthService adminAuthService,
  }) : _api = api,
       _tokenStorage = tokenStorage,
       _authService = authService,
       _roleService = roleService,
       _adminAuthService = adminAuthService;

  final DioApiService _api;
  final TokenStorage _tokenStorage;
  final AuthService _authService;
  final RoleService _roleService;
  final AdminAuthService _adminAuthService;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final session = await _authService.signInWithEmailPassword(email, password);
    final user = await _syncFirebaseSession(session);
    unawaited(_ensureUserDocument(session));
    return user;
  }

  Future<AppUser?> restoreSession() async {
    final session = await _authService.currentSession();
    if (session == null) {
      await _tokenStorage.clearToken();
      return null;
    }

    final user = await _syncFirebaseSession(session);
    unawaited(_ensureUserDocument(session));
    return user;
  }

  Future<AppUser> adminLogin({
    required String email,
    required String password,
  }) async {
    final session = await _adminAuthService.signInAdmin(
      email: email,
      password: password,
    );
    final user = await _syncFirebaseSession(session);
    if (!user.isAdmin) {
      await logout();
      throw const AdminAccessDeniedException();
    }
    return user;
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final session = await _authService.registerWithEmailPassword(
      email: email,
      password: password,
      fullName: fullName,
    );
    final user = await _syncFirebaseSession(session, phone: phone);
    unawaited(_ensureUserDocument(session));
    return user;
  }

  Future<AppUser> signInWithGoogle() async {
    final session = await _authService.signInWithGoogle();
    final user = await _syncFirebaseSession(session);
    unawaited(_ensureUserDocument(session));
    return user;
  }

  Future<void> logout() async {
    await _authService.signOut();
    await _tokenStorage.clearToken();
  }

  Future<AppUser> _syncFirebaseSession(
    FirebaseAuthSession session, {
    String? phone,
  }) async {
    final data =
        await _api.post('/auth/firebase-login', {'idToken': session.idToken})
            as Map<String, dynamic>;
    final user = AppUser.fromJson(data).copyWith(
      id: session.uid,
      email: session.email,
      fullName: session.displayName,
      token: session.idToken,
      phone: phone,
    );
    await _tokenStorage.saveToken(user.token);
    return user;
  }

  Future<void> _ensureUserDocument(FirebaseAuthSession session) async {
    try {
      await _roleService.ensureUserDocument(
        uid: session.uid,
        email: session.email,
        displayName: session.displayName,
      );
    } catch (_) {
      // Login should not be blocked by best-effort Firestore profile setup.
    }
  }
}
