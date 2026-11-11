import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../models/commerce.dart';
import '../../presentation/widgets/content_width.dart';
import '../../services/analytics/analytics.dart';
import '../../services/auth/auth_service.dart';
import '../../services/payments/razorpay_checkout.dart';
import '../../services/shop/cart_service.dart';
import '../../services/shop/stores.dart';
import '../../theme/app_theme.dart';
import '../account/addresses_screen.dart';
import 'cart_widgets.dart';
import '../home/home_screen.dart' show formatPrice;
import '../orders/my_orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _address;
  final PaymentMethod _payment = PaymentMethodStore.cod;

  @override
  void initState() {
    super.initState();
    final addresses = context.read<AddressStore>().items;
    if (addresses.isNotEmpty) _address = addresses.first;
    final cart = context.read<CartService>();
    Analytics.instance
      ..screen('checkout')
      ..beginCheckout(value: cart.total, itemCount: cart.lines.length);
    _checkDelivery();
    _checkOnlinePayments();
  }

  bool _placing = false;
  String? _error;
  bool _serviceable = true;

  // Online payment needs the server to have Razorpay keys, and a device that
  // can open the payment sheet.
  bool _onlineAvailable = false;
  bool _payOnline = false;

  Future<void> _checkOnlinePayments() async {
    final api = context.read<ApiClient?>();
    if (api == null || !onlinePaymentSupported) return;
    final features = await api.features();
    if (mounted) setState(() => _onlineAvailable = features.onlinePayments);
  }

  // Asks the server whether a local team delivers to the chosen address.
  Future<void> _checkDelivery() async {
    final address = _address;
    if (address == null) return;
    final ok = await context.read<OrderStore>().canDeliverTo(address.pin);
    if (mounted && _address == address) setState(() => _serviceable = ok);
  }

  Future<void> _place() async {
    final cart = context.read<CartService>();
    final orders = context.read<OrderStore>();
    final user = context.read<AuthService>().user;
    setState(() {
      _placing = true;
      _error = null;
    });
    if (orders.isRemote) {
      try {
        var order = await orders.place(
          lines: cart.lines,
          address: _address!,
          online: _payOnline,
        );
        if (_payOnline) {
          // The order exists and waits for payment. If paying fails or is
          // cancelled it stays in My orders with a Pay now button.
          try {
            order = await orders.payOnline(order, user!);
          } on PaymentFailure catch (e) {
            if (!mounted) return;
            setState(() {
              _placing = false;
              _error = e.cancelled
                  ? 'Payment not completed. Your order is saved in My orders, where you can pay or cancel it.'
                  : '${e.message} Your order is saved in My orders.';
            });
            return;
          }
        }
        _trackPurchase(order);
        cart.clear();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => OrderPlacedScreen(order: order)),
        );
      } on ApiException catch (e) {
        if (mounted) {
          setState(() {
            _placing = false;
            _error = e.message;
          });
        }
      }
      return;
    }
    final order = Order(
      id: 'DW${newId().toUpperCase()}',
      createdAt: DateTime.now(),
      lines: [for (final l in cart.lines) CartLine.fromJson(l.toJson())],
      address: _address!,
      payment: _payment,
      subtotal: cart.subtotal,
      tax: cart.tax,
      total: cart.total,
    );
    await orders.upsert(order, atFront: true);
    _trackPurchase(order);
    cart.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderPlacedScreen(order: order)),
    );
  }

  /// An order was placed. Sends the total and the items, never the address.
  void _trackPurchase(Order order) => Analytics.instance.purchase(
    orderId: order.id,
    value: order.total,
    paymentMethod: _payOnline ? 'online' : 'cod',
    items: [
      for (final l in order.lines)
        Analytics.item(
          id: l.productId,
          name: l.title,
          price: l.unitPrice,
          quantity: l.quantity,
          variant: l.size,
        ),
    ],
  );

  Future<void> _pickAddress() async {
    final a = await Navigator.of(context).push<Address>(
      MaterialPageRoute(builder: (_) => const AddressesScreen(pickMode: true)),
    );
    if (a != null) {
      setState(() => _address = a);
      _checkDelivery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final remote = context.read<OrderStore>().isRemote;
    final error = Theme.of(context).colorScheme.error;
    final canPlace =
        _address != null && !cart.isEmpty && !_placing && _serviceable;
    final rule = CartPalette.of(context).rule;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: LayoutBuilder(
        builder: (context, box) {
          final left = <Widget>[
            PillRow(
              icon: Icons.location_on_outlined,
              title: _address == null
                  ? 'Add a delivery address'
                  : '${_address!.label} · ${_address!.name}',
              subtitle: _address?.oneLine,
              onTap: _pickAddress,
            ),
            const SizedBox(height: 26),
            // As in the design: Cash on delivery or Pay online, always.
            PaymentChoices(
              online: _payOnline,
              onChanged: (v) {
                if (v && !(remote && _onlineAvailable)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Online payment is not available right now. Cash on delivery is selected.',
                      ),
                    ),
                  );
                  return;
                }
                setState(() => _payOnline = v);
              },
            ),
            const SizedBox(height: 30),
            for (final l in cart.lines) OrderLineRow(line: l),
            Divider(color: rule, thickness: 2, height: 28),
          ];
          final summary = SummaryCard(
            subtotal: cart.subtotal,
            tax: cart.tax,
            total: cart.total,
            actionLabel: _placing
                ? 'Placing order…'
                : _payOnline
                ? 'Pay ${formatPrice(cart.total)}'
                : 'Place order',
            onAction: canPlace ? _place : null,
            notes: [
              if (!_serviceable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'We do not deliver to ${_address!.pin} yet. Choose another address.',
                    style: TextStyle(color: error),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_error!, style: TextStyle(color: error)),
                ),
            ],
          );
          final footnote = Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              remote
                  ? 'Prices are confirmed by the store when you place the order.'
                  : 'Orders are saved on this device until the store backend is connected.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.muted),
            ),
          );
          // A wide window: the details on the left and the summary on the
          // right, like the cart.
          if (box.maxWidth >= 880) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ListView(children: left)),
                      const SizedBox(width: 56),
                      SizedBox(
                        width: 360,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [summary, footnote],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return ContentWidth(
            maxWidth: 728,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              children: [...left, const SizedBox(height: 4), summary, footnote],
            ),
          );
        },
      ),
    );
  }
}

class OrderPlacedScreen extends StatelessWidget {
  const OrderPlacedScreen({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final p = CartPalette.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 410,
            constraints: const BoxConstraints(maxWidth: 410),
            padding: const EdgeInsets.all(38),
            decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.panelBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.accent,
                  ),
                  child: Icon(
                    Icons.check,
                    color: context.isDark
                        ? const Color(0xFF171717)
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Order placed',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thanks for shopping with DesignWear. Your order is being prepared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.muted, height: 1.5),
                ),
                const SizedBox(height: 10),
                Text('#${order.id} · ${formatPrice(order.total)}'),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                    ),
                    child: const Text('View my orders'),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Continue shopping'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
