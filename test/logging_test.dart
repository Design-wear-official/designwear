import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/logging/app_log.dart';
import 'package:designwear/screens/settings/diagnostics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a log line shows a picture for the tag instead of brackets', () {
    final line = LogEntry(
      at: DateTime.utc(2026, 10, 31),
      level: LogLevel.error,
      tag: 'api',
      message: 'GET /v1/orders -> 500',
    ).toString();
    expect(line, contains('🌐 api GET /v1/orders -> 500'));
    expect(line, isNot(contains('[api]')));
    expect(
      LogEntry(
        at: DateTime.now(),
        level: LogLevel.info,
        tag: 'new',
        message: 'x',
      ).tagIcon,
      '🔹',
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('redact removes tokens, passwords and emails', () {
    final out = redact(
      'user a@b.com password=hunter2 Bearer abc.def.ghi "token": "xyz" eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1XzEifQ.c2lnbmF0dXJl',
    );
    for (final secret in [
      'a@b.com',
      'hunter2',
      'abc.def.ghi',
      'xyz',
      'eyJhbGciOiJIUzI1',
    ]) {
      expect(out.contains(secret), isFalse, reason: secret);
    }
  });

  test('keeps a bounded local log and persists it', () async {
    final log = AppLog.forTest();
    for (var i = 0; i < AppLog.maxInMemory + 20; i++) {
      log.info('t', 'line $i');
    }
    expect(log.entries.length, AppLog.maxInMemory);
    expect(log.entries.last.message, 'line ${AppLog.maxInMemory + 19}');
    await Future<void>.delayed(const Duration(seconds: 3));
    final reloaded = AppLog.forTest();
    await reloaded.load();
    expect(reloaded.entries.length, AppLog.maxOnDisk);
  });

  test(
    'sends only warnings and errors, redacted, in one batch; opt-out stops it',
    () async {
      final bodies = <Map>[];
      final api = ApiClient(
        'https://api.example.com',
        httpClient: MockClient((r) async {
          bodies.add(jsonDecode(r.body) as Map);
          return http.Response(
            '{"accepted":1}',
            202,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final log = AppLog.forTest()..attach(api: api, flavour: 'external');
      log.debug('t', 'noise');
      log.info('t', 'chatter');
      log.warning('t', 'slow for a@b.com');
      log.error('t', 'boom', 'Bearer secret.token.value', StackTrace.current);
      await log.flush();
      expect(bodies, hasLength(1));
      final entries = (bodies.single['entries'] as List).cast<Map>();
      expect(entries.map((e) => e['level']), ['warning', 'error']);
      expect(jsonEncode(bodies), isNot(contains('a@b.com')));
      expect(jsonEncode(bodies), isNot(contains('secret.token.value')));
      expect((bodies.single['app'] as Map)['flavour'], 'external');

      await log.setRemoteEnabled(false);
      log.error('t', 'not sent');
      await log.flush();
      expect(bodies, hasLength(1));
      expect(
        log.entries.last.message,
        'not sent',
        reason: 'still kept locally',
      );
    },
  );

  test('network failure keeps the queue for a retry; logging the upload cannot loop', () async {
    var fail = true;
    var calls = 0;
    final api = ApiClient(
      'https://api.example.com',
      httpClient: MockClient((r) async {
        calls++;
        if (fail) throw http.ClientException('offline');
        return http.Response(
          '{}',
          202,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final log = AppLog.forTest()..attach(api: api, flavour: 'external');
    log.error('t', 'first');
    await log.flush();
    expect(calls, 1);
    expect(
      log.entries.where((e) => e.tag == 'api'),
      isEmpty,
      reason: 'upload failures are not logged',
    );
    fail = false;
    await log.flush();
    expect(calls, 2);
    await log.flush();
    expect(calls, 2, reason: 'queue is empty after success');
  });

  testWidgets('diagnostics screen lists, filters and clears', (tester) async {
    final log = AppLog.forTest()
      ..info('app', 'hello')
      ..error('app', 'kaboom');
    await tester.pumpWidget(MaterialApp(home: DiagnosticsScreen(log: log)));
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('kaboom'), findsOneWidget);
    await tester.tap(find.text('Errors'));
    await tester.pump();
    expect(find.text('hello'), findsNothing);
    expect(find.text('Logs stay on this device'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear log'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing logged'), findsOneWidget);
    await tester.pump(
      const Duration(seconds: 3),
    ); // let the debounced save timer finish
  });
}
