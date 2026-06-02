import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/utils/responsive_utils.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Payment Methods',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          final methods = authService.currentUser?.paymentMethods ?? [];

          if (methods.isEmpty) {
            return Center(
              child: Text(
                'No saved payment methods',
                style: GoogleFonts.outfit(color: Theme.of(context).hintColor),
              ),
            );
          }

          return ListView(
            padding: ResponsiveSizes.pagePadding(context),
            children: [
              Text(
                'Saved Methods',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...methods.map((pm) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPaymentCard(
                    context,
                    type: pm['type'] ?? 'Card',
                    last4: pm['last4'] ?? '••••',
                    exp: pm['exp'] ?? '',
                    icon: pm['type'] == 'UPI' ? Icons.account_balance_wallet : Icons.credit_card,
                    isDefault: pm['isDefault'] ?? false,
                  ),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddPaymentDialog(context);
        },
        backgroundColor: colorScheme.primary,
        icon: Icon(Icons.add, color: colorScheme.onPrimary),
        label: Text('Add New Card', style: TextStyle(color: colorScheme.onPrimary)),
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context) {
    final typeCtrl = TextEditingController(text: 'Credit Card');
    final last4Ctrl = TextEditingController();
    final expCtrl = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Payment Method', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: typeCtrl.text,
                      items: ['Credit Card', 'Debit Card', 'UPI'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => typeCtrl.text = val);
                      },
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: last4Ctrl,
                      decoration: const InputDecoration(labelText: 'Identifier (e.g., Last 4 Digits or UPI ID)'),
                    ),
                    TextField(controller: expCtrl, decoration: const InputDecoration(labelText: 'Expiry (e.g., 12/25)')),
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
                    authService.addPaymentMethod({
                      'type': typeCtrl.text,
                      'last4': last4Ctrl.text,
                      'exp': expCtrl.text,
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

  Widget _buildPaymentCard(BuildContext context, {
    required String type,
    required String last4,
    required String exp,
    required IconData icon,
    required bool isDefault,
  }) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$type •••• $last4',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires $exp',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          if (isDefault)
            Icon(Icons.check_circle, color: colorScheme.primary)
        ],
      ),
    );
  }
}

