import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/widgets/content_width.dart';
import '../../services/shop/cart_service.dart';
import '../../theme/app_theme.dart';
import '../account/auth_screens.dart';
import 'checkout_screen.dart';
import '../home/home_screen.dart' show formatPrice;
import '../catalog/product_image.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (!cart.isEmpty)
            TextButton(onPressed: cart.clear, child: const Text('Clear')),
        ],
      ),
      body: ContentWidth(
        child: cart.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: context.muted,
                    ),
                    SizedBox(height: 12),
                    Text('Your cart is empty'),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cart.lines.length,
                      separatorBuilder: (_, _) => const Divider(height: 24),
                      itemBuilder: (_, i) {
                        final line = cart.lines[i];
                        return Row(
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ProductImage(url: line.imageUrl),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Size ${line.size}',
                                    style: TextStyle(color: context.muted),
                                  ),
                                  Text(
                                    formatPrice(line.total),
                                    style: TextStyle(
                                      color: context.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Decrease',
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: context.accent,
                              ),
                              onPressed: () =>
                                  cart.setQuantity(line, line.quantity - 1),
                            ),
                            Text('${line.quantity}'),
                            IconButton(
                              tooltip: 'Increase',
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: context.accent,
                              ),
                              onPressed: () =>
                                  cart.setQuantity(line, line.quantity + 1),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  _Summary(cart: cart),
                ],
              ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart});
  final CartService cart;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row('Subtotal', formatPrice(cart.subtotal)),
          _row('GST (18%)', formatPrice(cart.tax)),
          const Divider(),
          _row('Total', formatPrice(cart.total), bold: true),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                if (!await requireSignIn(context)) return;
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              },
              child: const Text('Checkout'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _row(String l, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
        Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
      ],
    ),
  );
}
