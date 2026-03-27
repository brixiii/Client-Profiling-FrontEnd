import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class ApiService {
  ApiService({http.Client? client, TokenStorage? tokenStorage})
      : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _client;
  final TokenStorage _tokenStorage;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool requiresAuth = true,
  }) {
    return _request(
      'GET',
      path,
      query: query,
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool requiresAuth = true,
  }) {
    return _request(
      'POST',
      path,
      body: body,
      query: query,
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool requiresAuth = true,
  }) {
    return _request(
      'PUT',
      path,
      body: body,
      query: query,
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool requiresAuth = true,
  }) {
    return _request(
      'PATCH',
      path,
      body: body,
      query: query,
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool requiresAuth = true,
  }) {
    return _request(
      'DELETE',
      path,
      body: body,
      query: query,
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    required bool requiresAuth,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseApiUrl}$path').replace(
      queryParameters: _cleanQuery(query),
    );

    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final encodedBody = body == null ? null : jsonEncode(body);

    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(uri, headers: headers, body: encodedBody);
        break;
      case 'PUT':
        response = await _client.put(uri, headers: headers, body: encodedBody);
        break;
      case 'PATCH':
        response =
            await _client.patch(uri, headers: headers, body: encodedBody);
        break;
      case 'DELETE':
        response =
            await _client.delete(uri, headers: headers, body: encodedBody);
        break;
      default:
        throw ApiException(
            statusCode: 500, message: 'Unsupported HTTP method.');
    }

    final decoded = _decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException.fromResponse(
      statusCode: response.statusCode,
      decodedBody: decoded,
    );
  }

  Future<Map<String, String>> _buildHeaders(
      {required bool requiresAuth}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Map<String, String>? _cleanQuery(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return null;

    final cleaned = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty) continue;
      cleaned[entry.key] = text;
    }
    return cleaned.isEmpty ? null : cleaned;
  }

  dynamic _decode(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return <String, dynamic>{'message': rawBody};
    }
  }
}
