import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class DioApiService {
  DioApiService({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage,
      dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.resolvedApiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token;
          try {
            final firebaseUser = FirebaseAuth.instance.currentUser;
            if (firebaseUser != null) {
              token = await firebaseUser.getIdToken();
            }
          } catch (_) {}
          token ??= await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) => handler.next(error),
      ),
    );
  }

  final Dio dio;
  final TokenStorage _tokenStorage;

  Future<dynamic> get(String path) async {
    try {
      final response = await dio.get(path);
      return response.data;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await dio.post(path, data: body);
      return response.data;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await dio.delete(path);
      return response.data;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ApiException _mapError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final message = data is Map<String, dynamic>
        ? data['message']?.toString() ?? 'Request failed'
        : data?.toString() ?? error.message ?? 'Network error';
    return ApiException(message, statusCode: statusCode);
  }
}
