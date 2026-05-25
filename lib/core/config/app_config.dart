import 'package:flutter/foundation.dart';

class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'BELUMI_API_BASE_URL',
    defaultValue: 'http://localhost:5151/api',
  );

  static String get resolvedApiBaseUrl {
    if (kIsWeb) return apiBaseUrl;
    return apiBaseUrl.replaceFirst('localhost', '10.0.2.2');
  }
}
