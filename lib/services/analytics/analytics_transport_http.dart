import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_transport_base.dart';

/// Android, iOS and desktop: posts events to GA4's Measurement Protocol, so
/// every platform ends up in the same Google Analytics property.
///
/// The Measurement Protocol has no Firebase dependency and works on desktop,
/// where Firebase Analytics does not run.
AnalyticsTransport createTransport({http.Client? client}) =>
    HttpAnalyticsTransport(client: client);

class HttpAnalyticsTransport implements AnalyticsTransport {
  HttpAnalyticsTransport({http.Client? client, Random? random})
    : _client = client ?? http.Client(),
      _random = random ?? Random.secure();

  static const _clientIdKey = 'analytics_client_id';
  static const _endpoint = 'https://www.google-analytics.com/mp/collect';

  final http.Client _client;
  final Random _random;
  String? _measurementId;
  String? _apiSecret;
  String _clientId = '';
  bool _granted = false;

  /// GA groups events into a session by this number (seconds since epoch).
  final int _sessionId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  @override
  Future<void> start({
    required String measurementId,
    String? apiSecret,
    required bool granted,
  }) async {
    _measurementId = measurementId;
    _apiSecret = apiSecret;
    _granted = granted;
    _clientId = await _loadClientId();
  }

  /// An anonymous, random id kept on the device. It is not linked to the
  /// account, the email or anything else about the person.
  Future<String> _loadClientId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_clientIdKey);
      if (saved != null && saved.isNotEmpty) return saved;
      final fresh = _newClientId();
      await prefs.setString(_clientIdKey, fresh);
      return fresh;
    } catch (_) {
      return _newClientId();
    }
  }

  String _newClientId() =>
      '${_random.nextInt(1 << 31)}.${DateTime.now().millisecondsSinceEpoch ~/ 1000}';

  @override
  void setConsent(bool granted) => _granted = granted;

  /// The JSON GA4 expects. Public so tests can check it.
  @visibleForTesting
  Map<String, Object?> payload(AnalyticsEvent event) => {
    'client_id': _clientId,
    'events': [
      {
        'name': event.name,
        'params': {
          ...event.params,
          'session_id': _sessionId,
          'engagement_time_msec': 100,
        },
      },
    ],
    'user_properties': {
      'platform': {'value': _platform},
    },
  };

  String get _platform => kIsWeb ? 'web' : defaultTargetPlatform.name;

  @override
  void send(AnalyticsEvent event) {
    final id = _measurementId;
    final secret = _apiSecret;
    if (!_granted || id == null || secret == null || secret.isEmpty) return;
    final uri = Uri.parse(_endpoint)
        .replace(queryParameters: {'measurement_id': id, 'api_secret': secret});
    // Fire and forget: reporting must never slow down or break the app.
    unawaited(
      _client
          .post(
            uri,
            headers: {'content-type': 'application/json'},
            body: jsonEncode(payload(event)),
          )
          .timeout(const Duration(seconds: 10))
          .then<void>((_) {})
          .catchError((Object _) {}),
    );
  }
}
