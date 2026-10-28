import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../models/commerce.dart';
import '../../services/shop/cart_service.dart';
import '../../services/shop/stores.dart';
import '../account/addresses_screen.dart';
import '../home/home_screen.dart' show formatPrice;
import '../orders/my_orders_screen.dart';
import '../account/payment_methods_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _address;
  PaymentMethod _payment = PaymentMethodStore.cod;

  @override
  void initState() {
    super.initState();
    final addresses = context.read<AddressStore>().items;
    if (addresses.isNotEmpty) _address = addresses.first;
    _checkDelivery();
  }

  bool _placing = false;
  String? _error;
  bool _serviceable = true;

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
    setState(() {
      _placing = true;
      _error = null;
    });
    if (orders.isRemote) {
      try {
        final order = await orders.place(lines: cart.lines, address: _address!);
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
    cart.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderPlacedScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final remote = context.read<OrderStore>().isRemote;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(
                _address == null
                    ? 'Add a delivery address'
                    : '${_address!.label} · ${_address!.name}',
              ),
              subtitle: _address == null ? null : Text(_address!.oneLine),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final a = await Navigator.of(context).push<Address>(
                  MaterialPageRoute(
                    builder: (_) => const AddressesScreen(pickMode: true),
                  ),
                );
                if (a != null) {
                  setState(() => _address = a);
                  _checkDelivery();
                }
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(_payment.label),
              trailing: const Icon(Icons.chevron_right),
              subtitle: remote
                  ? const Text('Pay when your order arrives')
                  : null,
              onTap: remote
                  ? null
                  : () async {
                      final p = await Navigator.of(context).push<PaymentMethod>(
                        MaterialPageRoute(
                          builder: (_) =>
                              const PaymentMethodsScreen(pickMode: true),
                        ),
                      );
                      if (p != null) setState(() => _payment = p);
                    },
            ),
          ),
          const SizedBox(height: 8),
          for (final l in cart.lines)
            ListTile(
              dense: true,
              title: Text('${l.title}  ×${l.quantity}'),
              subtitle: Text('Size ${l.size}'),
              trailing: Text(formatPrice(l.total)),
            ),
          const Divider(),
          ListTile(
            dense: true,
            title: const Text('Subtotal'),
            trailing: Text(formatPrice(cart.subtotal)),
          ),
          ListTile(
            dense: true,
            title: const Text('GST (18%)'),
            trailing: Text(formatPrice(cart.tax)),
          ),
          ListTile(
            title: const Text(
              'Total',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: Text(
              formatPrice(cart.total),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          if (!_serviceable)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'We do not deliver to ${_address!.pin} yet. '
                'Choose another address.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed:
                _address == null || cart.isEmpty || _placing || !_serviceable
                ? null
                : _place,
            child: Text(_placing ? 'Placing order…' : 'Place order'),
          ),
          const SizedBox(height: 8),
          Text(
            remote
                ? 'Prices are confirmed by the store when you place the order.'
                : 'Orders are saved on this device until the store backend is connected.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class OrderPlacedScreen extends StatelessWidget {
  const OrderPlacedScreen({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Order placed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('#${order.id} · ${formatPrice(order.total)}'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              ),
              child: const Text('View my orders'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Continue shopping'),
            ),
          ],
        ),
      ),
    ),
  );
}
