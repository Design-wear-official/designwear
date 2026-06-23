import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/presentation/widgets/widgets.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/models/models.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  bool _couponLoading = false;
  String? _couponError;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(CartService cartService) async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _couponLoading = true;
      _couponError = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    // Demo: treat 'WELCOME10' as a valid 10% coupon
    if (code == 'WELCOME10') {
      cartService.applyCoupon(
        Coupon(
          code: code,
          discountPercent: 10,
          maxDiscountAmount: 200,
        ),
      );
      setState(() => _couponLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon applied! 10% off (max ₹200)', style: GoogleFonts.outfit()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      setState(() {
        _couponLoading = false;
        _couponError = 'Invalid or expired coupon code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Consumer<CartService>(
          builder: (_, cs, __) => ShaderMask(
            shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
            child: Text(
              cs.isEmpty ? 'My Cart' : 'My Cart (${cs.itemCount})',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          Consumer<CartService>(
            builder: (_, cs, __) => cs.isNotEmpty
                ? TextButton(
                    onPressed: () => _confirmClearCart(context, cs),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.isEmpty) return _EmptyCart();
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

  Widget _buildCartContent(BuildContext context, CartService cartService) {
    return ListView(
      padding: ResponsiveSizes.pagePadding(context),
      children: [
        // Items
        ...cartService.items.map(
          (item) => _CartItemTile(
            item: item,
            cartService: cartService,
          ),
        ),

        const SizedBox(height: 16),

        // Coupon section
        _CouponSection(
          controller: _couponController,
          couponLoading: _couponLoading,
          couponError: _couponError,
          appliedCoupon: cartService.appliedCoupon,
          onApply: () => _applyCoupon(cartService),
          onRemove: () {
            cartService.removeCoupon();
            _couponController.clear();
            setState(() => _couponError = null);
          },
        ),

        const SizedBox(height: 24),

        // Delivery info banner
        _DeliveryBanner(),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, CartService cartService) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: ResponsiveSizes.contentPadding(context),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
            _PriceRow(label: 'Subtotal', value: '₹${cartService.subtotal.toStringAsFixed(2)}'),
            if (cartService.hasCoupon) ...[
              const SizedBox(height: 6),
              _PriceRow(
                label: 'Coupon (${cartService.appliedCoupon!.code})',
                value: '− ₹${cartService.couponDiscount.toStringAsFixed(2)}',
                valueColor: Colors.green,
              ),
            ],
            const SizedBox(height: 6),
            _PriceRow(
              label: 'Tax (${cartService.currentTaxRate}% GST)',
              value: '₹${cartService.tax.toStringAsFixed(2)}',
              small: true,
            ),
            const SizedBox(height: 4),
            _PriceRow(
              label: 'Shipping',
              value: cartService.subtotal >= 499 ? 'FREE' : '₹49.00',
              valueColor: cartService.subtotal >= 499 ? Colors.green : null,
              small: true,
            ),
            const Divider(height: 20),
            _PriceRow(
              label: 'Total',
              value: '₹${cartService.total.toStringAsFixed(2)}',
              bold: true,
              large: true,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppColors.neonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBlue.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'PROCEED TO CHECKOUT',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context, CartService cs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Cart?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Remove all items from your cart?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cs.clearCart();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear All', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Cart Item Tile ─────────────────────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final CartService cartService;
  const _CartItemTile({required this.item, required this.cartService});

  @override
  Widget build(BuildContext context) {
    final imgSize = ResponsiveUtils.getResponsiveValue<double>(
      context, mobile: 88, tablet: 110, desktop: 120,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('${item.product.id}_${item.selectedSize}_${item.selectedColor}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove item'),
            content: Text('Remove "${item.product.title}" from your cart?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => cartService.removeFromCart(item.product.id, size: item.selectedSize),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardDark
              : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.hairDark
                : AppColors.hairLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.06,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.product.imageUrl != null
                  ? SafeNetworkImage(
                      imageUrl: item.product.imageUrl!,
                      width: imgSize, height: imgSize, fit: BoxFit.cover,
                    )
                  : Container(
                      width: imgSize, height: imgSize,
                      color: colorScheme.onSurface.withOpacity(0.1),
                      child: Icon(Icons.image, color: colorScheme.onSurface.withOpacity(0.3)),
                    ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (item.selectedSize != null)
                        _Tag(text: 'Size: ${item.selectedSize}'),
                      if (item.selectedColor != null)
                        _Tag(text: 'Color: ${item.selectedColor}'),
                      if (item.customDesign != null)
                        _Tag(text: 'Custom', color: AppColors.purple),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.product.price.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      _QuantityControls(
                        quantity: item.quantity,
                        onDecrement: () => cartService.decrementQuantity(
                          item.product.id, size: item.selectedSize,
                        ),
                        onIncrement: () => cartService.incrementQuantity(
                          item.product.id, size: item.selectedSize,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color? color;
  const _Tag({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: c)),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _QuantityControls({required this.quantity, required this.onDecrement, required this.onIncrement});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.hairDark : AppColors.hairLight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('$quantity', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          _QtyBtn(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 16)),
    );
    return kIsWeb ? MouseRegion(cursor: SystemMouseCursors.click, child: btn) : btn;
  }
}

// ── Coupon Section ────────────────────────────────────────────────────────────

class _CouponSection extends StatelessWidget {
  final TextEditingController controller;
  final bool couponLoading;
  final String? couponError;
  final Coupon? appliedCoupon;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const _CouponSection({
    required this.controller,
    required this.couponLoading,
    this.couponError,
    this.appliedCoupon,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (appliedCoupon != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coupon "${appliedCoupon!.code}" applied',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  Text(
                    '${appliedCoupon!.discountPercent.toInt()}% off',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.green.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRemove,
              child: Text('Remove', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Have a coupon?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  hintStyle: GoogleFonts.outfit(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: couponError,
                  isDense: true,
                ),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: couponLoading ? null : onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.textOnGold,
                  disabledBackgroundColor: AppColors.gold.withOpacity(0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: couponLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnGold))
                    : Text('APPLY', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 2),
          child: Text(
            'Try WELCOME10 for 10% off your first order',
            style: GoogleFonts.outfit(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.45)),
          ),
        ),
      ],
    );
  }
}

// ── Delivery Banner ───────────────────────────────────────────────────────────

class _DeliveryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Free delivery on orders above ₹499',
              style: GoogleFonts.outfit(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price Row ─────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool large;
  final bool small;
  final Color? valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.large = false,
    this.small = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = large ? 19.0 : small ? 13.0 : 15.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: bold ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (bold ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.85)),
          ),
        ),
      ],
    );
  }
}

// ── Empty Cart ────────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.surface
                    : AppColors.gray900,
                border: Border.all(
                  color: isDark ? AppColors.hairDark : AppColors.hairLight,
                ),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 52,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.gray500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to your cart to get started',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(
                    'Continue Shopping',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: AppColors.textOnGold,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
