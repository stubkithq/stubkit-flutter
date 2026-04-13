import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class StubkitHTTP {
  final String _apiKey;
  final String _baseUrl;
  final http.Client _client;

  static const _userAgent = 'stubkit-flutter/1.0.0';
  static const _maxRetries = 2;
  static const _backoffMs = [250, 500];

  StubkitHTTP({
    required String apiKey,
    required String baseUrl,
    http.Client? client,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'User-Agent': _userAgent,
      };

  Future<Map<String, dynamic>> get(String path) async {
    return _requestWithRetry('GET', path);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _requestWithRetry('POST', path, body: body);
  }

  Future<Map<String, dynamic>> _requestWithRetry(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse('$_baseUrl$path');
        http.Response response;

        if (method == 'POST') {
          response = await _client.post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : '{}',
          );
        } else {
          response = await _client.get(uri, headers: _headers);
        }

        if (response.statusCode >= 500 && attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: _backoffMs[attempt]));
          continue;
        }

        return _parseEnvelope(response.body);
      } on StubkitError {
        rethrow;
      } catch (e) {
        lastError = e;
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: _backoffMs[attempt]));
          continue;
        }
      }
    }

    throw lastError ?? StubkitError('unknown', 'Request failed after retries');
  }

  Map<String, dynamic> _parseEnvelope(String responseBody) {
    final envelope = jsonDecode(responseBody) as Map<String, dynamic>;
    final success = envelope['success'] as bool? ?? false;

    if (!success) {
      final error = envelope['error'] as Map<String, dynamic>?;
      final code = error?['code'] as String? ?? 'unknown';
      final message = error?['message'] as String? ?? 'Unknown error';
      throw StubkitError(code, message);
    }

    return envelope['data'] as Map<String, dynamic>? ?? {};
  }
}
