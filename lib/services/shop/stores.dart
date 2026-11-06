import '../../api/api_client.dart';
import '../../models/commerce.dart';
import '../../models/return_request.dart';
import '../app/persisted_list.dart';
import '../payments/razorpay_checkout.dart';

class AddressStore extends PersistedList<Address> {
  AddressStore()
    : super(
        key: 'addresses.v1',
        fromJson: Address.fromJson,
        toJson: (a) => a.toJson(),
        idOf: (a) => a.id,
      );
}

class PaymentMethodStore extends PersistedList<PaymentMethod> {
  PaymentMethodStore()
    : super(
        key: 'payments.v1',
        fromJson: PaymentMethod.fromJson,
        toJson: (p) => p.toJson(),
        idOf: (p) => p.id,
      );

  /// Cash on delivery is always available.
  static const cod = PaymentMethod(
    id: 'cod',
    kind: PaymentKind.cod,
    label: 'Cash on delivery',
  );
  List<PaymentMethod> get all => [cod, ...items];
}

/// Orders. With an [ApiClient] they live on the server and are priced there;
/// otherwise they are kept on this device.
class OrderStore extends PersistedList<Order> {
  OrderStore({this.api})
    : super(
        key: 'orders.v1',
        fromJson: Order.fromJson,
        toJson: (o) => o.toJson(),
        idOf: (o) => o.id,
      );

  final ApiClient? api;
  bool get isRemote => api != null;

  /// Server mode: reload this user's orders and returns. Errors leave the lists unchanged.
  Future<void> refresh() async {
    if (api == null || !api!.hasToken) return;
    try {
      final j = await api!.get('/v1/orders');
      setAll([
        for (final o in (j['orders'] as List)) Order.fromApi((o as Map).cast()),
      ]);
    } on ApiException catch (_) {}
    await refreshReturns();
  }

  final Map<String, ReturnRequest> _returns = {};

  /// The return asked for on [orderId] that still counts (a declined one is ignored), if any.
  ReturnRequest? returnFor(String orderId) => _returns[orderId];

  Future<void> refreshReturns() async {
    if (api == null || !api!.hasToken) return;
    try {
      final j = await api!.get('/v1/returns');
      _returns.clear();
      // Newest first from the server; keep the newest that is not declined,
      // else the newest declined one (so the person sees why).
      for (final r in (j['returns'] as List? ?? const []).reversed) {
        final req = ReturnRequest.fromApi((r as Map).cast());
        final have = _returns[req.orderId];
        if (have == null || req.isOpen || !have.isOpen) {
          _returns[req.orderId] = req;
        }
      }
      notifyListeners();
    } on ApiException catch (_) {}
  }

  /// Asks to return a delivered order. Throws [ApiException] with the server's reason when refused.
  Future<ReturnRequest> requestReturn(Order order, String reason) async {
    final j = await api!.post(
      '/v1/orders/${Uri.encodeComponent(order.id)}/return',
      {'reason': reason.trim()},
    );
    final req = ReturnRequest.fromApi((j['return'] as Map).cast());
    _returns[order.id] = req;
    notifyListeners();
    return req;
  }

  /// Whether a local team delivers to [pin]. Unknown (offline, errors) counts as
  /// yes: the server makes the final call when the order is placed.
  Future<bool> canDeliverTo(String pin) async {
    if (api == null) return true;
    try {
      final j = await api!.get('/v1/serviceability', query: {'pin': pin});
      return j['serviceable'] != false;
    } catch (_) {
      return true;
    }
  }

  /// Server mode: places the order; the server prices it from the catalog.
  /// With [online] the order waits for payment until [payOnline] succeeds.
  Future<Order> place({
    required List<CartLine> lines,
    required Address address,
    bool online = false,
  }) async {
    final j = await api!.post('/v1/orders', {
      'address': address.toJson(),
      'paymentMethod': online ? 'razorpay' : 'cod',
      'lines': [
        for (final l in lines)
          {
            'productId': l.productId,
            'designId': l.designId,
            'size': l.size,
            'quantity': l.quantity,
          },
      ],
    });
    final order = Order.fromApi((j['order'] as Map).cast());
    setAll([order, ...items.where((o) => o.id != order.id)]);
    return order;
  }

  /// Opens the payment sheet for an order that is waiting for payment, then lets
  /// the server verify it. Throws [PaymentFailure] if the person backs out or the
  /// payment fails, and [ApiException] if the server refuses.
  Future<Order> payOnline(Order order, UserProfile user) async {
    final created = await api!.post('/v1/payments/razorpay/order', {
      'orderId': order.id,
    });
    final result = await openRazorpay(
      PaymentRequest(
        keyId: '${created['keyId']}',
        razorpayOrderId: '${created['razorpayOrderId']}',
        amountPaise: (created['amount'] as num).toInt(),
        currency: '${created['currency']}',
        name: user.name,
        email: user.email,
        phone: order.address.phone,
      ),
    );
    final j = await api!.post('/v1/payments/razorpay/verify', {
      'orderId': order.id,
      'paymentId': result.paymentId,
      'signature': result.signature,
    });
    final paid = Order.fromApi((j['order'] as Map).cast());
    setAll([paid, ...items.where((o) => o.id != paid.id)]);
    return paid;
  }

  /// Asks the server to email the receipt for [order] again.
  Future<void> emailReceipt(Order order) async {
    await api!.post('/v1/orders/${Uri.encodeComponent(order.id)}/receipt');
  }

  Future<void> cancel(Order order) async {
    if (api == null) {
      return upsert(order.copyWith(status: OrderStatus.cancelled));
    }
    final j = await api!.post(
      '/v1/orders/${Uri.encodeComponent(order.id)}/cancel',
    );
    final updated = Order.fromApi((j['order'] as Map).cast());
    setAll([for (final o in items) o.id == updated.id ? updated : o]);
  }
}
