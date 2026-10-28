import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/product.dart';
import 'package:designwear/presentation/widgets/safe_network_image.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/screens/catalog/product_detail_screen.dart';

/// Small pill marking a card as a remixable community design, with the
/// creator handle. Shown only on designed garments (Product.isDesignedGarment).
class _RemixableChip extends StatelessWidget {
  final String? handle;
  final int remixCount;
  const _RemixableChip({this.handle, this.remixCount = 0});

  @override
  Widget build(BuildContext context) {
    final label = (handle != null && handle!.isNotEmpty)
        ? (handle!.startsWith('@') ? handle! : '@$handle')
        : 'Remixable';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: AppColors.marigold.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fork_right, color: AppColors.marigoldInk, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          if (remixCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '· $remixCount',
              style: TextStyle(
                color: AppColors.marigoldInk.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const HomeSectionTitle({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveSizes.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? hp + 12 : hp,
        isDesktop ? 28 : 24,
        isDesktop ? hp + 12 : hp,
        isDesktop ? 14 : 12,
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 5 : 4,
            height: isDesktop ? 26 : 20,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 10),
          // Takes the room left by "See All" and shortens with an ellipsis on a
          // very narrow screen, instead of overflowing.
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.archivo(
                fontSize: isDesktop ? 20 : 15,
                fontWeight: FontWeight.w800,
                letterSpacing: isDesktop ? 1.4 : 1.1,
                color: ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 12,
                vertical: isDesktop ? 7 : 5,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'See All →',
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.marigold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category chip list ────────────────────────────────────────────────────────

// ── Featured products row ─────────────────────────────────────────────────────

class HomeFeaturedProductsRow extends StatelessWidget {
  final Future<List<Product>> future;
  final bool isDesktop;
  final double hp;

  const HomeFeaturedProductsRow({
    super.key,
    required this.future,
    required this.isDesktop,
    required this.hp,
  });

  @override
  Widget build(BuildContext context) {
    final cardW = isDesktop ? 200.0 : 160.0;
    final cardH = isDesktop ? 280.0 : 230.0;

    return FutureBuilder<List<Product>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: cardH,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final card = isDark ? AppColors.cardDark : AppColors.cardLight;
        final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
        final ink = isDark ? AppColors.inkDark : AppColors.inkLight;

        return SizedBox(
          height: cardH,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? hp + 12 : hp),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              final p = snapshot.data![i];
              final tag = 'featured_${p.id}';
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(product: p, heroTag: tag),
                    settings: RouteSettings(name: '/product/${p.slug}'),
                  ),
                ),
                child: Container(
                  width: cardW,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: hair),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: cardH * 0.65,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: tag,
                                child: Container(
                                  color: isDark
                                      ? AppColors.backgroundLight
                                      : const Color(0xFFF5F4F0),
                                  child: p.displayImageUrl != null
                                      ? SafeNetworkImage(
                                          imageUrl: p.displayImageUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.image_not_supported,
                                          size: 36,
                                        ),
                                ),
                              ),
                              // Top-left: remixable chip for community designs, else NEW.
                              Positioned(
                                top: 8,
                                left: 8,
                                child: p.isDesignedGarment
                                    ? _RemixableChip(
                                        handle: p.creatorHandle,
                                        remixCount: p.remixCount,
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.marigold,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'NEW',
                                          style: TextStyle(
                                            color: AppColors.marigoldInk,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '₹${p.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.archivo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.marigold,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (p.rating > 0)
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                  if (p.rating > 0)
                                    Text(
                                      ' ${p.rating.toStringAsFixed(1)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.stone,
                                        fontWeight: FontWeight.w600,
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
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Product grid (all products) ───────────────────────────────────────────────

class HomeProductGrid extends StatelessWidget {
  final Future<List<Product>> future;
  final String searchQuery;
  final String? selectedCategoryId;
  final VoidCallback onRetry;
  final VoidCallback onClearFilters;

  const HomeProductGrid({
    super.key,
    required this.future,
    required this.searchQuery,
    required this.selectedCategoryId,
    required this.onRetry,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return GestureDetector(
            onTap: onRetry,
            child: Container(
              height: 200,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.orange, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No internet connection',
                    style: GoogleFonts.archivo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    'Pull down to refresh or tap to retry',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final q = searchQuery.toLowerCase();
        final filtered = snapshot.data!.where((p) {
          final matchesCat =
              selectedCategoryId == null || p.categoryId == selectedCategoryId;
          final matchesQ =
              q.isEmpty ||
              p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q);
          return matchesCat && matchesQ;
        }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  q.isNotEmpty
                      ? 'No results for "$q"'
                      : 'No products in this category',
                  style: GoogleFonts.archivo(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onClearFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.marigold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Clear filters',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.marigoldInk,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = ResponsiveUtils.isDesktop(context);
            final hPad = ResponsiveSizes.horizontalPadding(context);
            final outerPad = isDesktop ? hPad + 12 : hPad;
            final availableW = constraints.maxWidth - outerPad * 2;
            final cols = (availableW / 250).floor().clamp(2, 6);
            const spacing = 14.0;
            final cardW = (availableW - spacing * (cols - 1)) / cols;
            final cardH = cardW * 1.55;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final card = isDark ? AppColors.cardDark : AppColors.cardLight;
            final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
            final ink = isDark ? AppColors.inkDark : AppColors.inkLight;

            return Padding(
              padding: EdgeInsets.fromLTRB(outerPad, 8, outerPad, 8),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: filtered.map((p) {
                  final tag = 'grid_${p.id}';
                  return SizedBox(
                    width: cardW,
                    height: cardH,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(product: p, heroTag: tag),
                          settings: RouteSettings(name: '/product/${p.slug}'),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(
                            isDesktop ? 18 : 14,
                          ),
                          border: Border.all(color: hair),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            isDesktop ? 18 : 14,
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Hero(
                                  tag: tag,
                                  child: Container(
                                    color: isDark
                                        ? AppColors.backgroundLight
                                        : const Color(0xFFF5F4F0),
                                    child: p.displayImageUrl != null
                                        ? SafeNetworkImage(
                                            imageUrl: p.displayImageUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.image_not_supported,
                                            color: ink.withValues(alpha: 0.4),
                                            size: 36,
                                          ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_border,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                              // Special indication: remixable community design.
                              if (p.isDesignedGarment)
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: _RemixableChip(
                                    handle: p.creatorHandle,
                                    remixCount: p.remixCount,
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.88),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              p.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${p.price.toStringAsFixed(0)}',
                                              style: GoogleFonts.archivo(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.marigold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.marigold,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.add_shopping_cart,
                                          color: AppColors.marigoldInk,
                                          size: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}
