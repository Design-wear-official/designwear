import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/commerce.dart';
import '../../services/shop/stores.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key, this.pickMode = false});
  final bool pickMode;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PaymentMethodStore>();
    return Scaffold(
      appBar: AppBar(
        title: Text(pickMode ? 'Payment method' : 'Payment methods'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addUpi(context),
        icon: const Icon(Icons.add),
        label: const Text('Add UPI ID'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          for (final m in store.all)
            ListTile(
              leading: Icon(
                m.kind == PaymentKind.cod
                    ? Icons.payments_outlined
                    : Icons.account_balance_wallet_outlined,
              ),
              title: Text(m.label),
              subtitle: Text(
                m.kind == PaymentKind.cod
                    ? 'Pay when delivered'
                    : 'UPI (collected on delivery for now)',
              ),
              onTap: pickMode ? () => Navigator.of(context).pop(m) : null,
              trailing: m.id == PaymentMethodStore.cod.id
                  ? null
                  : IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => store.remove(m.id),
                    ),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Online card and UPI payments need the payment gateway, which '
              'is not connected. Card numbers are never stored in the app.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addUpi(BuildContext context) async {
    final store = context.read<PaymentMethodStore>();
    final controller = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add UPI ID'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'name@bank'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (id != null && RegExp(r'^[\w.\-]{2,}@[\w]{2,}$').hasMatch(id)) {
      await store.upsert(
        PaymentMethod(id: newId(), kind: PaymentKind.upi, label: id),
      );
    }
  }
}
