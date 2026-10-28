import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/commerce.dart';
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
