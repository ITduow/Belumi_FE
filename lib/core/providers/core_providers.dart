import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_api_service.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiServiceProvider = Provider<DioApiService>((ref) {
  return DioApiService(tokenStorage: ref.watch(tokenStorageProvider));
});
