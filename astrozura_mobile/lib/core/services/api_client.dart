import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_services.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? _sharedClient;

  static final http.Client _sharedClient = http.Client();
  static final Map<String, _CachedApiResponse> _getCache = {};
  static const Duration cacheTtl = Duration(minutes: 3);
  final http.Client _client;

  static const Duration timeout = Duration(seconds: 20);

  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    final uri = Uri.parse(url).replace(
      queryParameters: query?.isEmpty == true ? null : query,
    );
    final cacheKey = uri.toString();
    final cached = auth ? null : _freshCache(cacheKey);
    if (cached != null) return Map<String, dynamic>.from(cached);

    final headers = await _headers(auth: auth);
    try {
      final response = await _withRetry(
        () => _client.get(uri, headers: headers).timeout(timeout),
      );
      final decoded = _decodeResponse(response);
      if (!auth) {
        _getCache[cacheKey] = _CachedApiResponse(decoded, DateTime.now());
      }
      return decoded;
    } catch (_) {
      final stale = auth ? null : _getCache[cacheKey]?.data;
      if (stale != null) return Map<String, dynamic>.from(stale);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final headers = await _headers(auth: auth);
    final encodedBody = jsonEncode(body ?? <String, dynamic>{});
    final response = await _withRetry(
      () => _client
          .post(Uri.parse(url), headers: headers, body: encodedBody)
          .timeout(timeout),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final headers = await _headers(auth: auth);
    final encodedBody = jsonEncode(body ?? <String, dynamic>{});
    final response = await _withRetry(
      () => _client
          .put(Uri.parse(url), headers: headers, body: encodedBody)
          .timeout(timeout),
    );
    return _decodeResponse(response);
  }

  Future<http.Response> _withRetry(
    Future<http.Response> Function() request,
  ) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await request();
        if (response.statusCode < 500 || attempt == 1) return response;
      } on TimeoutException catch (_) {
        if (attempt == 1) rethrow;
      } on SocketException catch (_) {
        if (attempt == 1) rethrow;
      } on http.ClientException catch (_) {
        if (attempt == 1) rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    throw const ApiException('The server did not respond. Please try again.');
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw const ApiException('Please login again.', statusCode: 401);
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.trim();
    dynamic decoded;

    if (body.isEmpty) {
      decoded = <String, dynamic>{};
    } else {
      decoded = jsonDecode(body);
    }

    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};

    if (response.statusCode == 401) {
      throw ApiException(
        _messageFrom(data, 'Session expired. Please login again.'),
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _messageFrom(data, 'Request failed (${response.statusCode}).'),
        statusCode: response.statusCode,
      );
    }

    final status = data['status']?.toString().toLowerCase();
    if (data['success'] == false || status == 'error') {
      throw ApiException(_messageFrom(data, 'Request failed.'));
    }

    return data;
  }

  static String _messageFrom(Map<String, dynamic> data, String fallback) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final messages = errors.values.expand((value) {
        if (value is List) return value.map((item) => item.toString());
        return [value.toString()];
      }).where((value) => value.trim().isNotEmpty);
      if (messages.isNotEmpty) return messages.join(', ');
    }

    return fallback;
  }

  static Map<String, dynamic>? _freshCache(String key) {
    final cached = _getCache[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.createdAt) > cacheTtl) return null;
    return cached.data;
  }
}

class _CachedApiResponse {
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const _CachedApiResponse(this.data, this.createdAt);
}
