// The token API below is marked deprecated in favour of a newer installation-id
// flow whose server side is not settled yet; the token API still works.
// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';
import '../../logging/app_log.dart';
import 'notification_service.dart';

/// Phone notifications through Firebase Cloud Messaging. Works on Android and iOS
/// when this build has Firebase set up; everywhere else it does nothing, and the
/// in-app inbox still shows every message.
class PushService {
  PushService({required this.api, required this.inbox, this.onForeground});

  final ApiClient api;
  final NotificationService inbox;

  /// Called with the message text when one arrives while the app is open.
  final void Function(String title, String body)? onForeground;

  String? _token;
  final _subscriptions = <StreamSubscription<Object?>>[];

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) &&
      Firebase.apps.isNotEmpty;

  /// After sign-in: ask permission, then tell the server which phone this is.
  Future<void> start() async {
    if (!supported) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      await _register(await messaging.getToken());
      _subscriptions
        ..add(messaging.onTokenRefresh.listen(_register))
        ..add(
          FirebaseMessaging.onMessage.listen((message) {
            final n = message.notification;
            if (n != null) onForeground?.call(n.title ?? '', n.body ?? '');
            inbox.refresh();
          }),
        )
        ..add(
          FirebaseMessaging.onMessageOpenedApp.listen((_) => inbox.refresh()),
        );
    } catch (e) {
      AppLog.instance.warning('push', 'Phone notifications could not start', e);
    }
  }

  Future<void> _register(String? token) async {
    if (token == null || !api.hasToken) return;
    _token = token;
    try {
      await api.post('/v1/me/devices', {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      });
    } catch (e) {
      AppLog.instance.warning('push', 'Could not register this phone', e);
    }
  }

  /// Signing out: this phone stops getting that account's messages.
  Future<void> stop() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    final token = _token;
    _token = null;
    try {
      if (token != null && api.hasToken) {
        await api.request('DELETE', '/v1/me/devices', body: {'token': token});
      }
      // The session may already be gone, so also retire this phone's token: the
      // server drops it the next time it is used. The next person to sign in on
      // this phone gets a fresh one.
      if (supported) await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}
