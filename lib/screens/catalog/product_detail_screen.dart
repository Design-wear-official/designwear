import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:designwear/presentation/widgets/safe_network_image.dart';
import 'package:designwear/models/product.dart';
import 'package:designwear/services/shop/cart_service.dart';
import 'package:designwear/presentation/patterns/responsive_typography_pattern.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/theme/app_theme.dart' show AppThemeColors;
import 'package:designwear/models/models.dart' show CustomDesign;

import '../studio/editor/design_studio_screen.dart';

import '../cart/cart_screen.dart';
import '../home/home_app_bar.dart' show HomeBrand;
import '../ai/virtual_tryon_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String? heroTag;

  const ProductDetailScreen({super.key, required this.product, this.heroTag});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  final List<String> _sizes = ['S', 'M', 'L', 'XL', 'XXL'];
  bool _isAddingToCart = false;
  bool _isBuyingNow = false;

  // Side by side from this width up; below it the phone layout is used.
  static const _wideBreakpoint = 900.0;
  static const _wideMaxWidth = 1600.0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    if (wide) return _wide(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surface
              .withValues(alpha: 0.8),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...[
              _hero(context, wide: false),
              _tryOn(context),
              _remixButton(context),
              _info(context),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSizes.horizontalPadding(context),
          vertical: ResponsiveSizes.buttonPaddingVertical(context),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.1),
            ),
          ),
        ),
        child: SafeArea(
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Row(
                children: [
                  // Add to Cart Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          (widget.product.stockStatus == 'outOfStock' ||
                              _isAddingToCart)
                          ? null
                          : () => _addToCart(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        side: BorderSide(color: AppColors.marigold, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isAddingToCart
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.marigold,
                              ),
                            )
                          : Text(
                              'ADD TO CART',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: AppColors.marigold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Buy Now Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: AppColors.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.marigold.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed:
                            (widget.product.stockStatus == 'outOfStock' ||
                                _isBuyingNow)
                            ? null
                            : () => _buyNow(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: AppColors.marigoldInk,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isBuyingNow
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.marigoldInk,
                                ),
                              )
                            : Text(
                                widget.product.stockStatus == 'outOfStock'
                                    ? 'OUT OF STOCK'
                                    : 'BUY NOW',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: AppColors.marigoldInk,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _remix() {
    final p = widget.product;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DesignStudioScreen(
          initialDesign: CustomDesign(name: '${p.title} remix'),
          remixProduct: p,
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a size', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isAddingToCart = true);

    // Small delay so the loading state is visible — feels intentional
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    context.read<CartService>().addToCart(widget.product, size: _selectedSize);
    setState(() => _isAddingToCart = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Added to cart!', style: GoogleFonts.poppins()),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _buyNow() async {
    if (_selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a size', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isBuyingNow = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    context.read<CartService>().addToCart(widget.product, size: _selectedSize);
    setState(() => _isBuyingNow = false);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  // Desktop: the whole page is the dark background, with a full-width header and
  // three columns: picture, details, and a buy box (like a shop product page).
  Widget _wide(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = widget.product;
    final outOfStock = p.stockStatus == 'outOfStock';
    final text = Theme.of(context).textTheme;
    final line = scheme.onSurface.withValues(alpha: 0.12);
    // A separate buy box needs room; narrower desktops keep the buttons in the
    // details column instead.
    final threeColumns = MediaQuery.sizeOf(context).width >= 1180;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: line)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left, size: 20),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                        side: BorderSide(color: line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: HomeBrand(ink: scheme.onSurface, compact: false),
                  ),
                ),
                const SizedBox(width: 140),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _wideMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 28, 40, 48),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _hero(context, wide: true),
                          ),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                style: text.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    '₹${p.price.toStringAsFixed(2)}',
                                    style: ResponsiveTypography.price(context)
                                        .copyWith(color: context.accent),
                                  ),
                                  const SizedBox(width: 16),
                                  _stockChip(context),
                                ],
                              ),
                              Divider(height: 40, color: line),
                              Text(
                                'Select Size',
                                style: ResponsiveTypography.h4(context),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  for (final size in _sizes)
                                    _SizeChip(
                                      size: size,
                                      isSelected: _selectedSize == size,
                                      onTap: () => setState(
                                        () => _selectedSize =
                                            _selectedSize == size ? null : size,
                                      ),
                                    ),
                                ],
                              ),
                              if (p.description.isNotEmpty) ...[
                                Divider(height: 40, color: line),
                                Text(
                                  'About this item',
                                  style: ResponsiveTypography.h4(context),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  p.description,
                                  style: ResponsiveTypography.body(
                                    context,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.75,
                                    ),
                                  ).copyWith(height: 1.5),
                                ),
                              ],
                              Divider(height: 40, color: line),
                              _wideButton(
                                context,
                                icon: Icons.fork_right,
                                label: 'Remix this T-shirt',
                                onPressed: _remix,
                                filled: true,
                              ),
                              _wideButton(
                                context,
                                icon: Icons.auto_awesome,
                                label: 'Try It On Virtually ✨',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        VirtualTryOnScreen(product: p),
                                  ),
                                ),
                              ),
                              if (!threeColumns) ...[
                                const SizedBox(height: 8),
                                ..._buyButtons(context, outOfStock),
                              ],
                            ],
                          ),
                        ),
                        if (threeColumns) ...[
                          const SizedBox(width: 40),
                          SizedBox(
                            width: 320,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: line),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${p.price.toStringAsFixed(2)}',
                                    style: text.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Inclusive of all taxes',
                                    style: text.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _stockChip(context),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedSize == null
                                        ? 'Choose a size to continue'
                                        : 'Size $_selectedSize',
                                    style: text.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._buyButtons(context, outOfStock),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buyButtons(BuildContext context, bool outOfStock) => [
    _wideButton(
      context,
      label: _isAddingToCart ? 'Adding…' : 'Add to cart',
      onPressed: outOfStock || _isAddingToCart ? null : _addToCart,
      solid: AppColors.marigold,
    ),
    _wideButton(
      context,
      label: outOfStock ? 'Out of stock' : 'Buy now',
      onPressed: outOfStock || _isBuyingNow ? null : _buyNow,
      solid: const Color(0xFFFFB300),
    ),
  ];

  Widget _stockChip(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _stockColor(widget.product).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      widget.product.isLowStock
          ? widget.product.stockLabel
          : _getStockText(widget.product.stockStatus),
      style: TextStyle(
        color: _stockColor(widget.product),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );

  // Full-width pill buttons stacked in the details column.
  Widget _wideButton(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool filled = false,
    Color? solid,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    );
    final child = Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: (filled || solid != null) ? AppColors.marigoldInk : null,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: solid != null
            ? ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: solid,
                  foregroundColor: AppColors.marigoldInk,
                  elevation: 0,
                  shape: shape,
                ),
                child: child,
              )
            : filled
            ? ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, color: AppColors.marigoldInk),
                label: child,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.marigold,
                  elevation: 0,
                  shape: shape,
                ),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: icon == null
                    ? const SizedBox.shrink()
                    : Icon(icon, color: AppColors.marigold),
                label: child,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(
                    color: icon == null
                        ? Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.25)
                        : AppColors.marigold,
                    width: 1.5,
                  ),
                  shape: shape,
                ),
              ),
      ),
    );
  }

  Widget _hero(BuildContext context, {required bool wide}) => Hero(
    tag: widget.heroTag ?? widget.product.id,
    child: Container(
      width: double.infinity,
      height: wide
          ? null
          : ResponsiveUtils.getResponsiveValue<double>(
              context,
              mobile: MediaQuery.sizeOf(context).height * 0.50,
              tablet: MediaQuery.sizeOf(context).height * 0.55,
              desktop: MediaQuery.sizeOf(context).height * 0.60,
            ),
      decoration: BoxDecoration(
        color: wide
            ? const Color(0xFFF8F8F8)
            : Theme.of(context).colorScheme.surface,
        borderRadius: wide
            ? BorderRadius.circular(28)
            : const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
      ),
      child: ClipRRect(
        borderRadius: wide
            ? BorderRadius.circular(28)
            : const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
        child: widget.product.imageUrl != null
            ? SafeNetworkImage(
                imageUrl: widget.product.imageUrl!,
                fit: wide ? BoxFit.contain : BoxFit.cover,
              )
            : Icon(
                Icons.image_not_supported,
                size: 100,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
      ),
    ),
  );

  Widget _tryOn(BuildContext context) => Column(
    children: [
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSizes.horizontalPadding(context),
          vertical: 16.0,
        ),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VirtualTryOnScreen(product: widget.product),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome, color: AppColors.marigold),
            label: Text(
              'Try It On Virtually ✨',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.marigold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.marigold, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _remixButton(BuildContext context) => Column(
    children: [
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSizes.horizontalPadding(context),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _remix,
            icon: const Icon(Icons.fork_right, color: AppColors.marigoldInk),
            label: Text(
              'REMIX THIS T-SHIRT',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppColors.marigoldInk,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.marigold,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _info(BuildContext context) => Padding(
    padding: EdgeInsets.all(ResponsiveSizes.horizontalPadding(context)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.title.toUpperCase(),
              style: ResponsiveTypography.h3(
                context,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ).copyWith(letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${widget.product.price.toStringAsFixed(2)}',
              style: ResponsiveTypography.price(context)
                  .copyWith(color: context.accent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _stockColor(widget.product).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.product.isLowStock
                ? widget.product.stockLabel
                : _getStockText(widget.product.stockStatus),
            style: TextStyle(
              color: _stockColor(widget.product),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Size Selection
        Text('Select Size', style: ResponsiveTypography.h4(context)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _sizes.map((size) {
            final isSelected = _selectedSize == size;
            return _SizeChip(
              size: size,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedSize = isSelected ? null : size;
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        Text(
          'Description',
          style: ResponsiveTypography.h4(context)
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.description,
          style: ResponsiveTypography.body(
            context,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.7),
          ).copyWith(height: 1.5),
        ),
        const SizedBox(height: 40),
      ],
    ),
  );

  // Amber when only a few are left, otherwise by availability.
  Color _stockColor(Product p) =>
      p.isLowStock ? Colors.orange : _getStockColor(p.stockStatus);

  Color _getStockColor(String status) {
    switch (status) {
      case 'inStock':
        return Colors.green;
      case 'outOfStock':
        return Colors.red;
      case 'preOrder':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStockText(String status) {
    switch (status) {
      case 'inStock':
        return 'In Stock';
      case 'outOfStock':
        return 'Out of Stock';
      case 'preOrder':
        return 'Pre-order Available';
      default:
        return 'Availability Unknown';
    }
  }
}

/// Animated size selector chip with scale feedback and web hover cursor.
class _SizeChip extends StatefulWidget {
  final String size;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeChip({
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SizeChip> createState() => _SizeChipState();
}

class _SizeChipState extends State<_SizeChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.reverse();
  void _onTapUp(TapUpDetails _) => _controller.forward();
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    final chip = GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          // 56×56 ensures ≥48dp touch target on all phones
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.marigold
                  : Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.2),
              width: widget.isSelected ? 2.0 : 1.5,
            ),
            color: widget.isSelected ? AppColors.marigold : Colors.transparent,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.marigold.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.size,
            style: GoogleFonts.outfit(
              color: widget.isSelected
                  ? AppColors.marigoldInk
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );

    if (kIsWeb) {
      return MouseRegion(cursor: SystemMouseCursors.click, child: chip);
    }
    return chip;
  }
}
