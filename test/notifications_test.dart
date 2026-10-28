import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/screens/notifications/notifications_screen.dart';
import 'package:designwear/services/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_app.dart';

Map<String, Object?> item(String id, String title, {bool read = false}) => {
  'id': id,
  'type': 'order.placed',
  'title': title,
  'body': 'Order #DW1 update',
  'orderId': 'DW1',
  'at': '2026-10-28T10:00:00.000Z',
  'read': read,
};

Future<(ApiClient, List<http.Request>)> signedInClient(
  List<Map<String, Object?>> items,
) async {
  SharedPreferences.setMockInitialValues({});
  final seen = <http.Request>[];
  final client = ApiClient(
    'https://api.example.com',
    httpClient: MockClient((request) async {
      seen.add(request);
      return http.Response(
        jsonEncode({'items': items, 'unread': 0, 'ok': true}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  await client.setToken('t');
  return (client, seen);
}

void main() {
  test('the inbox counts unread messages and marks them read', () async {
    final (api, seen) = await signedInClient([
      item('1', 'Order placed'),
      item('2', 'Order confirmed', read: true),
    ]);
    final inbox = NotificationService(api: api);
    await inbox.refresh();
    expect(inbox.items.map((n) => n.title), [
      'Order placed',
      'Order confirmed',
    ]);
    expect(inbox.unread, 1);

    await inbox.markAllRead();
    expect(inbox.unread, 0);
    expect(
      seen.any(
        (r) => r.method == 'POST' && r.url.path == '/v1/notifications/read',
      ),
      isTrue,
    );

    inbox.clear();
    expect(inbox.items, isEmpty, reason: 'signing out empties the inbox');
  });

  test('without an API or a session it does nothing', () async {
    final inbox = NotificationService();
    await inbox.refresh();
    expect(inbox.items, isEmpty);
  });

  testWidgets('the notifications screen lists messages and clears the badge', (
    tester,
  ) async {
    final (api, _) = await signedInClient([item('1', 'Order on its way')]);
    final inbox = NotificationService(api: api);
    await tester.pumpWidget(testApp(const NotificationsScreen(), inbox: inbox));
    await tester.pumpAndSettle();
    expect(find.text('Order on its way'), findsOneWidget);
    expect(inbox.unread, 0, reason: 'opening the inbox marks everything read');
  });
}
