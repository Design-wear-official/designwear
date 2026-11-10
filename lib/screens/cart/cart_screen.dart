import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/shop/cart_service.dart';
import '../../theme/app_theme.dart';
import '../account/auth_screens.dart';
import 'cart_widgets.dart';
import 'checkout_screen.dart';

/// The cart: the lines on the left and the summary on the right on a wide
/// window; the lines with the summary below them on a phone.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context) async {
    if (!await requireSignIn(context)) return;
    if (!context.mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: cart.clear,
              child: Text(
                'Clear',
                style: TextStyle(
                  color: context.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _Empty(onShop: () => Navigator.of(context).maybePop())
          : LayoutBuilder(
              builder: (context, box) {
                final items = [
                  for (final line in cart.lines) ...[
                    CartItemCard(
                      line: line,
                      onQuantity: (q) => cart.setQuantity(line, q),
                    ),
                    const SizedBox(height: 14),
                  ],
                ];
                final summary = SummaryCard(
                  subtotal: cart.subtotal,
                  tax: cart.tax,
                  total: cart.total,
                  actionLabel: 'Checkout',
                  onAction: () => _checkout(context),
                );
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
                            Expanded(child: ListView(children: items)),
                            const SizedBox(width: 56),
                            SizedBox(width: 360, child: summary),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        children: items,
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: summary,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onShop});
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shopping_bag_outlined, size: 48, color: context.muted),
        const SizedBox(height: 12),
        const Text('Your cart is empty'),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onShop,
          child: const Text('Continue shopping'),
        ),
      ],
    ),
  );
}
