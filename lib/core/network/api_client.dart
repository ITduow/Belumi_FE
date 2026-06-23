import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({String? baseUrl, Future<String?> Function()? tokenProvider})
    : baseUrl = baseUrl ?? AppConfig.resolvedApiBaseUrl,
      _tokenProvider = tokenProvider;

  final String baseUrl;
  final Future<String?> Function()? _tokenProvider;
  String? token;

  Future<String?> _resolveToken() async {
    if (_tokenProvider != null) {
      try {
        final t = await _tokenProvider!();
        if (t != null) return t;
      } catch (_) {}
    }
    return token;
  }

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri)..fields.addAll(fields);
    final resolvedToken = await _resolveToken();
    if (resolvedToken != null) {
      request.headers['Authorization'] = 'Bearer $resolvedToken';
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(response.body),
        statusCode: response.statusCode,
      );
    }

    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body);
  Future<dynamic> patch(String path, dynamic body) =>
      _send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    dynamic body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    final resolvedToken = await _resolveToken();
    print('ApiClient token value: "$resolvedToken"');
    if (resolvedToken != null) {
      headers['Authorization'] = 'Bearer $resolvedToken';
    }

    final response = switch (method) {
      'GET' => await http.get(uri, headers: headers),
      'POST' => await http.post(uri, headers: headers, body: jsonEncode(body)),
      'PUT' => await http.put(uri, headers: headers, body: jsonEncode(body)),
      'PATCH' => await http.patch(uri, headers: headers, body: jsonEncode(body)),
      'DELETE' => await http.delete(uri, headers: headers),
      _ => throw UnsupportedError('Unsupported method $method'),
    };

    if (response.statusCode < 200 || response.statusCode >= 300) {
      print('ApiClient Error: $method $path -> ${response.statusCode}');
      print('ApiClient Error Body: "${response.body}"');
      throw ApiException(
        _errorMessage(response.body),
        statusCode: response.statusCode,
      );
    }

    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  String _errorMessage(String body) {
    if (body.isEmpty) return 'Request failed.';

    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['detail'] ?? data['title'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Fall through to returning the raw body.
    }

    return body;
  }
}
