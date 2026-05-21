import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'role_service.dart';

class AdminAccessDeniedException implements Exception {
  const AdminAccessDeniedException();

  @override
  String toString() => 'You are not allowed to access admin panel.';
}

class AdminAuthService {
  const AdminAuthService({
    required AuthService authService,
    required RoleService roleService,
  }) : _authService = authService,
       _roleService = roleService;

  final AuthService _authService;
  final RoleService _roleService;

  Future<FirebaseAuthSession> signInAdmin({
    required String email,
    required String password,
  }) async {
    final session = await _authService.signInWithEmailPassword(email, password);

    try {
      final role = await _roleService.getRole(session.uid);
      if (role != 'admin') {
        await _authService.signOut();
        throw const AdminAccessDeniedException();
      }
      return session;
    } on FirebaseAuthException {
      rethrow;
    } on AdminAccessDeniedException {
      rethrow;
    } catch (_) {
      await _authService.signOut();
      throw const AdminAccessDeniedException();
    }
  }
}
