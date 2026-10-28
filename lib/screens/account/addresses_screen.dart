import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/commerce.dart';
import '../../services/shop/stores.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key, this.pickMode = false});

  /// When true, tapping an address returns it to the caller.
  final bool pickMode;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AddressStore>();
    return Scaffold(
      appBar: AppBar(
        title: Text(pickMode ? 'Choose address' : 'Shipping addresses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
      ),
      body: store.items.isEmpty
          ? const Center(child: Text('No addresses yet'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final a in store.items)
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text('${a.label} · ${a.name}'),
                    subtitle: Text('${a.oneLine}\n${a.phone}'),
                    isThreeLine: true,
                    onTap: pickMode
                        ? () => Navigator.of(context).pop(a)
                        : () => _edit(context, a),
                    trailing: IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => store.remove(a.id),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _edit(BuildContext context, [Address? existing]) async {
    final store = context.read<AddressStore>();
    final result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressForm(existing: existing),
    );
    if (result != null) await store.upsert(result);
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm({this.existing});
  final Address? existing;
  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  late final _c = {
    for (final k in ['label', 'name', 'phone', 'line1', 'city', 'state', 'pin'])
      k: TextEditingController(text: _initial(k)),
  };
  String? _error;

  String _initial(String k) {
    final a = widget.existing;
    if (a == null) return k == 'label' ? 'Home' : '';
    return a.toJson()[k] as String;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final v = {for (final e in _c.entries) e.key: e.value.text.trim()};
    if (v.values.any((s) => s.isEmpty)) {
      setState(() => _error = 'Fill in every field.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(v['pin']!)) {
      setState(() => _error = 'PIN code must be 6 digits.');
      return;
    }
    Navigator.of(context).pop(
      Address(
        id: widget.existing?.id ?? newId(),
        label: v['label']!,
        name: v['name']!,
        phone: v['phone']!,
        line1: v['line1']!,
        city: v['city']!,
        state: v['state']!,
        pin: v['pin']!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String key, String label, {TextInputType? type}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _c[key],
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field('label', 'Label (Home, Work…)'),
            field('name', 'Full name'),
            field('phone', 'Phone', type: TextInputType.phone),
            field('line1', 'Address'),
            field('city', 'City'),
            field('state', 'State'),
            field('pin', 'PIN code', type: TextInputType.number),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
