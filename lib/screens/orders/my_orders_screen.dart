import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../models/commerce.dart';
import '../../services/auth/auth_service.dart';
import '../../services/payments/razorpay_checkout.dart';
import '../../services/shop/stores.dart';
import '../home/home_screen.dart' show formatPrice;

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderStore>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<OrderStore>();
    final orders = store.items;
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: RefreshIndicator(
        onRefresh: store.refresh,
        child: orders.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No orders yet')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (_, i) => _OrderCard(order: orders[i]),
              ),
      ),
    );
  }
}

/// The steps an order goes through, with the ones reached ticked off.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});
  final Order order;

  static const _steps = [
    ('placed', 'Order placed'),
    ('confirmed', 'Confirmed'),
    ('packed', 'Packed'),
    ('shipped', 'Shipped'),
    ('delivered', 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    final reached = {for (final e in order.history) e.status: e};
    final cancelled = order.status == OrderStatus.cancelled;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (key, label) in _steps)
            _row(
              context,
              label: label,
              event: reached[key],
              color: reached.containsKey(key) ? scheme.primary : scheme.outline,
            ),
          if (cancelled)
            _row(
              context,
              label: 'Cancelled',
              event: reached['cancelled'],
              color: scheme.error,
            ),
          if (order.trackingId != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 32),
              child: Text(
                'Tracking: ${order.carrier ?? ''} ${order.trackingId}'.trim(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required OrderEvent? event,
    required Color color,
  }) {
    final done = event != null;
    final t = event?.at.toLocal();
    final when = t == null
        ? ''
        : '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} '
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event?.note == null ? label : '$label · ${event!.note}',
              style: TextStyle(
                fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                color: done ? null : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Text(when, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final d = order.createdAt;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text('#${order.id}'),
        subtitle: Text(
          '$date · ${order.status.name} · ${formatPrice(order.total)}',
        ),
        children: [
          for (final l in order.lines)
            ListTile(
              dense: true,
              title: Text(l.title),
              subtitle: Text('Size ${l.size} · ×${l.quantity}'),
              trailing: Text(formatPrice(l.total)),
            ),
          if (order.history.isNotEmpty) _Timeline(order: order),
          ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined),
            title: Text(order.address.oneLine),
            subtitle: Text('Pay: ${order.payment.label}'),
          ),
          if (order.teamName != null)
            ListTile(
              dense: true,
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text('Delivered by ${order.teamName}'),
            ),
          if (order.status == OrderStatus.awaitingPayment &&
              order.payment.kind == PaymentKind.online)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final orders = context.read<OrderStore>();
                  final user = context.read<AuthService>().user!;
                  try {
                    await orders.payOnline(order, user);
                  } on PaymentFailure catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text(e.message)));
                  } on ApiException catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text(e.message)));
                  }
                },
                child: Text('Pay ${formatPrice(order.total)} now'),
              ),
            ),
          if (order.status == OrderStatus.placed ||
              order.status == OrderStatus.awaitingPayment)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await context.read<OrderStore>().cancel(order);
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
                child: const Text('Cancel order'),
              ),
            ),
        ],
      ),
    );
  }
}
