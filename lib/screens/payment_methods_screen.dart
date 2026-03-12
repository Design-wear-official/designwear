import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Saved Cards',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentCard(
            context,
            type: 'Credit Card',
            last4: '4242',
            exp: '12/25',
            icon: Icons.credit_card,
            isDefault: true,
          ),
          const SizedBox(height: 12),
          _buildPaymentCard(
            context,
            type: 'Debit Card',
            last4: '1234',
            exp: '08/26',
            icon: Icons.credit_card,
            isDefault: false,
          ),
          const SizedBox(height: 32),
          Text(
            'Other Methods',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.account_balance_wallet, color: colorScheme.primary),
            title: Text('UPI Apps', style: TextStyle(color: colorScheme.onSurface)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).hintColor),
            tileColor: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment addition coming soon')),
          );
        },
        backgroundColor: colorScheme.primary,
        icon: Icon(Icons.add, color: colorScheme.onPrimary),
        label: Text('Add New Card', style: TextStyle(color: colorScheme.onPrimary)),
      ),
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
      padding: const EdgeInsets.all(16),
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
