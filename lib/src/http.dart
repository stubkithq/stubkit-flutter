import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// HTTP helper with two auth surfaces:
///  - publishable key (pk_live_...): offerings, event tracking
///  - tenant JWT: entitlement reads, purchase sync
/// The caller picks which per request.
enum StubkitAuth { publishable, tenantJwt }

typedef GetAuthToken = Future<String> Function();

class StubkitHTTP {
  final String _publishableKey;
  final GetAuthToken _getAuthToken;
  final String _baseUrl;
  final http.Client _client;

  static const _userAgent = 'stubkit-flutter/1.0.1';
  static const _maxRetries = 2;
  static const _backoffMs = [250, 500];

  StubkitHTTP({
    required String publishableKey,
    required GetAuthToken getAuthToken,
    required String baseUrl,
    http.Client? client,
  })  : _publishableKey = publishableKey,
        _getAuthToken = getAuthToken,
        _baseUrl = baseUrl,
        _client = client ?? http.Client();

  Future<String> _bearer(StubkitAuth auth) async {
    switch (auth) {
      case StubkitAuth.publishable:
        return _publishableKey;
      case StubkitAuth.tenantJwt:
        return _getAuthToken();
    }
  }

  Future<Map<String, String>> _headers(StubkitAuth auth) async => {
        'Authorization': 'Bearer ${await _bearer(auth)}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      };

  Future<Map<String, dynamic>> get(String path, StubkitAuth auth) async {
    return _requestWithRetry('GET', path, auth: auth);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    required StubkitAuth auth,
  }) async {
    return _requestWithRetry('POST', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> _requestWithRetry(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required StubkitAuth auth,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final uri = Uri.parse('$_baseUrl$path');
        final headers = await _headers(auth);
        http.Response response;

        if (method == 'POST') {
          response = await _client.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : '{}',
          );
        } else {
          response = await _client.get(uri, headers: headers);
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
