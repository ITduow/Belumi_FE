import 'auth_service.dart';

class AdminAccessDeniedException implements Exception {
  const AdminAccessDeniedException();

  @override
  String toString() => 'You are not allowed to access admin panel.';
}

class AdminAuthService {
  const AdminAuthService({
    required AuthService authService,
  }) : _authService = authService;

  final AuthService _authService;

  Future<FirebaseAuthSession> signInAdmin({
    required String email,
    required String password,
  }) async {
    return _authService.signInWithEmailPassword(email, password);
  }
}
