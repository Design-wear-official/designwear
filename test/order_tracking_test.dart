import 'package:designwear/models/commerce.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> apiOrder(String status) => {
  'id': 'DW1',
  'createdAt': '2026-10-28T10:00:00.000Z',
  'status': status,
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
  'team': {'id': 't1', 'name': 'Pune Team'},
  'tracking': {'id': 'TRK9', 'carrier': 'Delhivery'},
  'history': [
    {'status': 'placed', 'at': '2026-10-28T10:00:00.000Z'},
    {'status': 'confirmed', 'at': '2026-10-28T11:00:00.000Z', 'note': 'Thanks!'},
  ],
};

void main() {
  test('server orders carry status, history, tracking and the team', () {
    final order = Order.fromApi(apiOrder('confirmed'));
    expect(order.status, OrderStatus.confirmed);
    expect(order.history.map((e) => e.status), ['placed', 'confirmed']);
    expect(order.history.last.note, 'Thanks!');
    expect(order.trackingId, 'TRK9');
    expect(order.carrier, 'Delhivery');
    expect(order.teamName, 'Pune Team');
    expect(Order.fromApi(apiOrder('packed')).status, OrderStatus.packed);
  });

  test('an order without history or tracking still parses', () {
    final j = apiOrder('placed')
      ..remove('history')
      ..remove('tracking')
      ..remove('team');
    final order = Order.fromApi(j);
    expect(order.history, isEmpty);
    expect(order.trackingId, isNull);
  });
}
