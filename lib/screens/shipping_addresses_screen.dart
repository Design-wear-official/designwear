import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/utils/responsive_utils.dart';

class ShippingAddressesScreen extends StatelessWidget {
  const ShippingAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Shipping Addresses',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          final addresses = authService.currentUser?.addresses ?? [];

          if (addresses.isEmpty) {
            return Center(
              child: Text(
                'No saved addresses. Add one below!',
                style: GoogleFonts.outfit(color: Theme.of(context).hintColor),
              ),
            );
          }

          return ListView.separated(
            padding: ResponsiveSizes.pagePadding(context),
            itemCount: addresses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final addr = addresses[index];
              return _buildAddressCard(
                context,
                name: addr['label'] ?? 'Address',
                address: '${addr['street']}\n${addr['city']}, ${addr['state']} ${addr['zipCode']}\n${addr['country']}',
                isDefault: addr['isDefault'] ?? false,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddAddressDialog(context);
        },
        backgroundColor: colorScheme.primary,
        icon: Icon(Icons.add, color: colorScheme.onPrimary),
        label: Text('Add New Address', style: TextStyle(color: colorScheme.onPrimary)),
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final zipCtrl = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Address', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label (e.g., Home)')),
                    TextField(controller: streetCtrl, decoration: const InputDecoration(labelText: 'Street Address')),
                    TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State'))),
                        const SizedBox(width: 16),
                        Expanded(child: TextField(controller: zipCtrl, decoration: const InputDecoration(labelText: 'ZIP Code'))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Set as default'),
                      value: isDefault,
                      onChanged: (val) => setState(() => isDefault = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    authService.addAddress({
                      'label': labelCtrl.text.isEmpty ? 'Other' : labelCtrl.text,
                      'street': streetCtrl.text,
                      'city': cityCtrl.text,
                      'state': stateCtrl.text,
                      'zipCode': zipCtrl.text,
                      'country': 'United States',
                      'isDefault': isDefault,
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildAddressCard(BuildContext context, {required String name, required String address, required bool isDefault}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: ResponsiveSizes.contentPadding(context),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault ? colorScheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          width: isDefault ? 2 : 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    name.toLowerCase() == 'home' ? Icons.home : Icons.business,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DEFAULT',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Theme.of(context).hintColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () {},
                child: Text('Edit', style: TextStyle(color: colorScheme.primary)),
              ),
              const SizedBox(width: 8),
              if (!isDefault)
                TextButton(
                  onPressed: () {},
                  child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

