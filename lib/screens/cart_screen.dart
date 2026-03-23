import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/safe_network_image.dart';
import '../services/cart_service.dart';
import '../models/cart.dart';
import 'checkout_screen.dart';
import '../utils/responsive_utils.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'YOUR CART',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.isEmpty) {
            return _buildEmptyCart(context);
          }
          return _buildCartContent(context, cartService);
        },
      ),
      bottomNavigationBar: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.isEmpty) return const SizedBox.shrink();
          return _buildBottomBar(context, cartService);
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started!',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSizes.horizontalPadding(context) + 12,
                vertical: ResponsiveSizes.buttonPaddingVertical(context),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: Text(
              'CONTINUE SHOPPING',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartService cartService) {
    return ListView.builder(
      padding: ResponsiveSizes.pagePadding(context),
      itemCount: cartService.items.length,
      itemBuilder: (context, index) {
        final item = cartService.items[index];
        return _buildCartItem(context, cartService, item);
      },
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartService cartService,
    CartItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
          ),
        ), // Minimal separator
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(0), // Sharp images
              child: item.product.imageUrl != null
                  ? SafeNetworkImage(
                      imageUrl: item.product.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.2),
                      child: Icon(
                        Icons.image,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.selectedSize != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Size: ${item.selectedSize}',
                        style: GoogleFonts.outfit(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (item.customDesign != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'CUSTOM DESIGN',
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${item.product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity Controls
            Column(
              children: [
                IconButton(
                  onPressed: () => cartService.removeFromCart(
                    item.product.id,
                    size: item.selectedSize,
                  ),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  iconSize: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => cartService.decrementQuantity(
                          item.product.id,
                          size: item.selectedSize,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => cartService.incrementQuantity(
                          item.product.id,
                          size: item.selectedSize,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.add, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartService cartService) {
    return Container(
      padding: ResponsiveSizes.contentPadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: GoogleFonts.outfit(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  '₹${cartService.subtotal.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax (${cartService.currentTaxRate}% GST)',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  '₹${cartService.tax.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '₹${cartService.total.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CheckoutScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveSizes.buttonPaddingVertical(context) + 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'PROCEED TO CHECKOUT',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
