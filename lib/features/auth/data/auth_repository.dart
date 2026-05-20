import '../../../core/network/dio_api_service.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/app_user.dart';
import 'firebase_auth_service.dart';

class AuthRepository {
  AuthRepository({
    required DioApiService api,
    required TokenStorage tokenStorage,
    required FirebaseAuthService firebaseAuthService,
  }) : _api = api,
       _tokenStorage = tokenStorage,
       _firebaseAuthService = firebaseAuthService;

  final DioApiService _api;
  final TokenStorage _tokenStorage;
  final FirebaseAuthService _firebaseAuthService;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final data =
        await _api.post('/auth/login', {'email': email, 'password': password})
            as Map<String, dynamic>;
    return _saveUser(AppUser.fromJson(data));
  }

  Future<AppUser> adminLogin({
    required String email,
    required String password,
  }) async {
    final data =
        await _api.post('/auth/admin-login', {
              'email': email,
              'password': password,
            })
            as Map<String, dynamic>;
    return _saveUser(AppUser.fromJson(data));
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final data =
        await _api.post('/auth/register', {
              'email': email,
              'password': password,
              'fullName': fullName,
              'phone': phone,
            })
            as Map<String, dynamic>;
    return _saveUser(AppUser.fromJson(data));
  }

  Future<AppUser> signInWithGoogle() async {
    final firebaseIdToken = await _firebaseAuthService
        .signInWithGoogleAndGetIdToken();

    final data =
        await _api.post('/auth/firebase-login', {'idToken': firebaseIdToken})
            as Map<String, dynamic>;
    return _saveUser(AppUser.fromJson(data));
  }

  Future<void> logout() async {
    await _firebaseAuthService.signOut();
    await _tokenStorage.clearToken();
  }

  Future<AppUser> _saveUser(AppUser user) async {
    await _tokenStorage.saveToken(user.token);
    return user;
  }
}
