import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logging/app_log.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  ApiException(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;

  bool get isUnauthenticated => status == 401;

  @override
  String toString() => message;
}

/// Client for the DesignWear API (see ~/designwear-server). Holds the session
/// token; every call except sign-in/up/config sends it as a Bearer header.
class ApiClient {
  ApiClient(String baseUrl, {http.Client? httpClient})
    : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
      _http = httpClient ?? http.Client() {
    final uri = Uri.tryParse(this.baseUrl);
    final local = uri?.host == 'localhost' || uri?.host == '127.0.0.1';
    if (uri == null ||
        !(uri.scheme == 'https' || (uri.scheme == 'http' && local))) {
      throw ArgumentError(
        'The API URL must use https (http is only allowed for localhost).',
      );
    }
  }

  static const _tokenKey = 'api.token.v1';

  final String baseUrl;
  final http.Client _http;
  String? _token;

  /// Called when the server says the session is no longer valid.
  void Function()? onSessionExpired;

  bool get hasToken => _token != null;

  Future<void> loadToken() async {
    try {
      _token = (await SharedPreferences.getInstance()).getString(_tokenKey);
    } catch (_) {}
  }

  Future<void> setToken(String? token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null) {
        await prefs.remove(_tokenKey);
      } else {
        await prefs.setString(_tokenKey, token);
      }
    } catch (_) {}
  }

  Future<Map<String, Object?>> request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['accept'] = 'application/json'
      ..followRedirects = false;
    if (_token != null) request.headers['authorization'] = 'Bearer $_token';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    // Log only method, path and outcome (never bodies, queries or tokens), and
    // never the log upload itself.
    final quiet = path == '/v1/logs';
    final watch = Stopwatch()..start();
    http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(timeout),
      );
    } on TimeoutException {
      if (!quiet) {
        AppLog.instance.warning(
          'api',
          '$method $path timed out after ${watch.elapsedMilliseconds}ms',
        );
      }
      throw ApiException(0, 'timeout', 'The server took too long to respond.');
    } catch (_) {
      if (!quiet) {
        AppLog.instance.warning('api', '$method $path failed: network error');
      }
      throw ApiException(
        0,
        'network',
        "Couldn't reach the server. Check your connection.",
      );
    }
    if (!quiet) {
      final line =
          '$method $path -> ${response.statusCode} ${watch.elapsedMilliseconds}ms';
      if (response.statusCode >= 500) {
        AppLog.instance.error('api', line);
      } else if (response.statusCode >= 400) {
        AppLog.instance.info('api', line);
      } else {
        AppLog.instance.debug('api', line);
      }
    }

    Map<String, Object?> json = const {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) json = decoded.cast<String, Object?>();
    } catch (_) {}

    if (response.statusCode >= 200 && response.statusCode < 300) return json;

    final error = (json['error'] as Map?)?.cast<String, Object?>() ?? const {};
    final exception = ApiException(
      response.statusCode,
      '${error['code'] ?? 'error'}',
      '${error['message'] ?? 'Something went wrong (${response.statusCode}).'}',
    );
    if (exception.isUnauthenticated &&
        _token != null &&
        !path.startsWith('/v1/auth/')) {
      await setToken(null);
      onSessionExpired?.call();
    }
    throw exception;
  }

  Future<Map<String, Object?>> get(String path, {Map<String, String>? query}) =>
      request('GET', path, query: query);
  Future<Map<String, Object?>> post(String path, [Object? body]) =>
      request('POST', path, body: body ?? const {});
  Future<Map<String, Object?>> put(String path, Object body) =>
      request('PUT', path, body: body);
  Future<Map<String, Object?>> patch(String path, Object body) =>
      request('PATCH', path, body: body);
  Future<Map<String, Object?>> delete(String path) => request('DELETE', path);

  /// What the server has switched on (chat, try-on, online payments).
  Future<ServerFeatures> features() async {
    try {
      final j = await get('/v1/config');
      return ServerFeatures(
        designAgent: j['designAgent'] == true,
        tryOn: j['tryOn'] == true,
        onlinePayments: j['onlinePayments'] == true,
      );
    } catch (_) {
      return const ServerFeatures();
    }
  }
}

class ServerFeatures {
  const ServerFeatures({
    this.designAgent = false,
    this.tryOn = false,
    this.onlinePayments = false,
  });
  final bool designAgent, tryOn, onlinePayments;
}
