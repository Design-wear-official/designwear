import 'package:designwear/api/api_client.dart';
import 'package:designwear/models/commerce.dart';
import 'package:designwear/config/app_constants.dart';
import 'package:designwear/screens/help/help_screen.dart';
import 'package:designwear/services/shop/stores.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_app.dart';

final _order = Order.fromApi({
  'id': 'DW1',
  'createdAt': '2026-10-28T10:00:00.000Z',
  'status': 'placed',
  'lines': [
    {
      'productId': 'p1',
      'title': 'Tee',
      'size': 'M',
      'quantity': 1,
      'unitPrice': 500,
    },
  ],
  'address': {
    'label': 'Home',
    'name': 'Ada',
    'phone': '9999999999',
    'line1': '1 Road',
    'city': 'Pune',
    'state': 'MH',
    'pin': '411001',
  },
  'payment': {'method': 'cod', 'status': 'pay_on_delivery'},
  'subtotal': 500,
  'tax': 90,
  'total': 590,
});

void main() {
  testWidgets('answers open on tap and the support email is copied', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(testApp(const HelpScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Can I cancel an order?'), findsOneWidget);
    expect(find.textContaining('until the team confirms it'), findsNothing);
    await tester.tap(find.text('Can I cancel an order?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('until the team confirms it'), findsOneWidget);

    await tester.tap(find.text(AppConstants.supportEmail));
    await tester.pumpAndSettle();
    expect(copied, AppConstants.supportEmail);
    expect(find.text('Email address copied'), findsOneWidget);
  });

  test(
    'emailReceipt asks the server to resend that order\'s receipt',
    () async {
      final seen = <String>[];
      final api = ApiClient(
        'https://api.example.com',
        httpClient: MockClient((request) async {
          seen.add('${request.method} ${request.url.path}');
          return http.Response(
            '{"sent":true}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final store = OrderStore(api: api);
      await store.emailReceipt(_order);
      expect(seen, ['POST /v1/orders/DW1/receipt']);
    },
  );
}
