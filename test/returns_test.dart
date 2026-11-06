import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/models/commerce.dart';
import 'package:designwear/models/return_request.dart';
import 'package:designwear/screens/account/profile_screen.dart';
import 'package:designwear/screens/orders/my_orders_screen.dart';
import 'package:designwear/services/auth/auth_service.dart';
import 'package:designwear/services/shop/stores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'order_tracking_test.dart' show apiOrder;
import 'test_app.dart';

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> deliveredOrder(DateTime at) {
  final j = apiOrder('delivered');
  j['history'] = [
    {'status': 'placed', 'at': '2026-10-28T10:00:00.000Z'},
    {'status': 'delivered', 'at': at.toUtc().toIso8601String()},
  ];
  return j;
}

Map<String, Object?> apiReturn(String status, {String? note}) => {
  'id': 'R1',
  'orderId': 'DW1',
  'reason': 'too small',
  'amount': 590,
  'status': status,
  'createdAt': '2026-11-01T10:00:00.000Z',
  'history': [
    {'status': 'requested', 'at': '2026-11-01T10:00:00.000Z'},
    if (note != null)
      {'status': status, 'at': '2026-11-02T10:00:00.000Z', 'note': note},
  ],
};

/// An OrderStore talking to a fake API that serves [orders] and [returns].
Future<(OrderStore, List<http.Request>)> remoteStore({
  required List<Map<String, Object?>> orders,
  List<Map<String, Object?>> returns = const [],
  http.Response Function(http.Request)? onReturn,
}) async {
  SharedPreferences.setMockInitialValues({});
  final seen = <http.Request>[];
  final api = ApiClient(
    'https://api.example.com',
    httpClient: MockClient((req) async {
      seen.add(req);
      if (req.url.path == '/v1/orders' && req.method == 'GET') {
        return _json(200, {'orders': orders});
      }
      if (req.url.path == '/v1/returns') {
        return _json(200, {'returns': returns});
      }
      if (req.url.path.endsWith('/return') && req.method == 'POST') {
        return onReturn?.call(req) ??
            _json(201, {'return': apiReturn('requested')});
      }
      return _json(404, {
        'error': {'code': 'not_found', 'message': 'no'},
      });
    }),
  );
  await api.setToken('tok');
  return (OrderStore(api: api), seen);
}

void main() {
  group('models', () {
    test('a staff account carries its role; a customer does not', () {
      final staff = UserProfile.fromJson({
        'name': 'Ravi',
        'email': 'r@x.com',
        'staff': {'role': 'vendor'},
      });
      expect(staff.isStaff, isTrue);
      expect(staff.staffRole, 'vendor');
      expect(UserProfile.fromJson(staff.toJson()).staffRole, 'vendor');
      final customer = UserProfile.fromJson({
        'name': 'Ada',
        'email': 'a@x.com',
        'staff': null,
      });
      expect(customer.isStaff, isFalse);
      expect(customer.copyWith(name: 'B').isStaff, isFalse);
    });

    test(
      'a return can be asked for only on a delivered order, inside the window',
      () {
        final now = DateTime.utc(2026, 11, 10, 12);
        final fresh = Order.fromApi(
          deliveredOrder(now.subtract(const Duration(days: 2))),
        );
        final old = Order.fromApi(
          deliveredOrder(now.subtract(const Duration(days: 8))),
        );
        expect(fresh.canReturn(now), isTrue);
        expect(old.canReturn(now), isFalse);
        expect(Order.fromApi(apiOrder('shipped')).canReturn(now), isFalse);
      },
    );

    test('return requests parse with the desk note, and declined ones may be asked again', () {
      final declined = ReturnRequest.fromApi(
        apiReturn('rejected', note: 'worn'),
      );
      expect(declined.status, ReturnStatus.rejected);
      expect(declined.note, 'worn');
      expect(declined.isOpen, isFalse);
      expect(ReturnRequest.fromApi(apiReturn('refunded')).isOpen, isTrue);
      expect(
        ReturnRequest.fromApi(apiReturn('requested')).label,
        'Return requested',
      );
    });
  });

  group('OrderStore returns', () {
    test('requests a return and remembers it', () async {
      final (store, seen) = await remoteStore(
        orders: [deliveredOrder(DateTime.now())],
      );
      await store.refresh();
      final order = store.items.single;
      final req = await store.requestReturn(order, '  too small ');
      expect(req.status, ReturnStatus.requested);
      expect(store.returnFor('DW1')?.id, 'R1');
      final post = seen.lastWhere((r) => r.method == 'POST');
      expect(post.url.path, '/v1/orders/DW1/return');
      expect(jsonDecode(post.body), {'reason': 'too small'});
    });

    test('the server’s refusal reaches the caller as its message', () async {
      final (store, _) = await remoteStore(
        orders: [deliveredOrder(DateTime.now())],
        onReturn: (_) => _json(409, {
          'error': {
            'code': 'window_closed',
            'message': 'Returns are accepted for 7 days after delivery.',
          },
        }),
      );
      await store.refresh();
      expect(
        () => store.requestReturn(store.items.single, 'late'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('7 days'),
          ),
        ),
      );
      expect(store.returnFor('DW1'), isNull);
    });

    test('refresh loads returns; a declined one is kept only when nothing newer is open', () async {
      final (store, _) = await remoteStore(
        orders: [deliveredOrder(DateTime.now())],
        returns: [
          apiReturn('requested')..['id'] = 'R2',
          apiReturn('rejected', note: 'worn'),
        ],
      );
      await store.refresh();
      expect(store.returnFor('DW1')?.id, 'R2');
    });
  });

  group('screens', () {
    testWidgets(
      'a delivered order offers a return; sending it shows its status',
      (tester) async {
        final (store, seen) = await remoteStore(
          orders: [deliveredOrder(DateTime.now())],
        );
        await tester.pumpWidget(testApp(const MyOrdersScreen(), orders: store));
        await tester.pumpAndSettle();
        await tester.tap(find.text('#DW1'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('return-button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('return-button')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('return-send')))
              .onPressed,
          isNull,
          reason: 'a reason is required',
        );
        await tester.enterText(
          find.byKey(const Key('return-reason')),
          'too small',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('return-send')));
        await tester.pumpAndSettle();

        expect(
          seen.where(
            (r) => r.method == 'POST' && r.url.path.endsWith('/return'),
          ),
          hasLength(1),
        );
        expect(find.byKey(const Key('return-status')), findsOneWidget);
        expect(find.text('Return requested'), findsOneWidget);
        expect(find.byKey(const Key('return-button')), findsNothing);
      },
    );

    testWidgets('no return button on an order delivered too long ago', (
      tester,
    ) async {
      final (store, _) = await remoteStore(
        orders: [
          deliveredOrder(DateTime.now().subtract(const Duration(days: 30))),
        ],
      );
      await tester.pumpWidget(testApp(const MyOrdersScreen(), orders: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('#DW1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('return-button')), findsNothing);
    });

    Future<AuthService> signedInAs(Map<String, Object?>? staff) async {
      SharedPreferences.setMockInitialValues({'api.token.v1': 'tok'});
      final api = ApiClient(
        'https://api.example.com',
        httpClient: MockClient(
          (req) async => _json(200, {
            'user': {
              'id': 'u1',
              'name': 'Ravi',
              'email': 'r@x.com',
              'staff': staff,
            },
          }),
        ),
      );
      final auth = AuthService(api: api);
      await auth.load();
      return auth;
    }

    testWidgets(
      'staff see a Staff group with the staff app; the CMS admin only for desk and owner',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          testApp(
            const ProfileScreen(),
            auth: await signedInAs({'role': 'vendor'}),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('DesignWear Staff app'), findsOneWidget);
        expect(find.text('SethuCMS admin'), findsNothing);

        await tester.pumpWidget(
          testApp(
            const ProfileScreen(),
            auth: await signedInAs({'role': 'owner'}),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('SethuCMS admin'), findsOneWidget);
      },
    );

    testWidgets('customers see no Staff group', (tester) async {
      await tester.pumpWidget(
        testApp(const ProfileScreen(), auth: await signedInAs(null)),
      );
      await tester.pumpAndSettle();
      expect(find.text('DesignWear Staff app'), findsNothing);
    });
  });
}
