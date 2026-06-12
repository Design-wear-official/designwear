import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/widgets/widgets.dart';
import 'package:designwear/screens/product_detail_screen.dart';
import 'package:designwear/screens/design_studio_screen.dart';
import 'home_constants.dart';

// ── Category icon quick-access row ──────────────────────────────────────────

class HomeCategoryIconRow extends StatelessWidget {
  final bool isDesktop;
  final double hp;
  final ValueChanged<int> onCategoryTap;
  /// Sanity-loaded quick links; if empty the static HomeConstants.catIcons are used as fallback.
  final List<CategoryQuickLink> quickLinks;

  const HomeCategoryIconRow({
    super.key,
    required this.isDesktop,
    required this.hp,
    required this.onCategoryTap,
    this.quickLinks = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Prefer Sanity data; fall back to compile-time constants
    final useSanity = quickLinks.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        height: isDesktop ? 90 : 82,
        child: useSanity
            ? _buildFromSanity(context)
            : _buildFromConstants(context),
      ),
    );
  }

  Widget _buildFromSanity(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? hp + 12 : hp),
      itemCount: quickLinks.length,
      itemBuilder: (context, i) {
        final link = quickLinks[i];
        final color = link.color;
        return GestureDetector(
          onTap: () {
            if (link.action == QuickLinkAction.designStudio) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DesignStudioScreen(),
                settings: const RouteSettings(name: '/design-studio'),
              ));
            } else {
              onCategoryTap(link.tabIndex);
            }
          },
          child: _IconCell(label: link.label, icon: link.icon, color: color, isDesktop: isDesktop),
        );
      },
    );
  }

  Widget _buildFromConstants(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? hp + 12 : hp),
      itemCount: HomeConstants.catIcons.length,
      itemBuilder: (context, i) {
        final cat = HomeConstants.catIcons[i];
        final color = cat['color'] as Color;
        return GestureDetector(
          onTap: () {
            if (cat['label'] == 'Design') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DesignStudioScreen(),
                settings: const RouteSettings(name: '/design-studio'),
              ));
            } else {
              const labelToTab = {'Trending': 6, 'New In': 7, 'Sale': 8, 'T-Shirts': 2, 'Hoodies': 3, 'Polo': 4};
              final idx = labelToTab[cat['label'] as String];
              if (idx != null) onCategoryTap(idx);
            }
          },
          child: _IconCell(label: cat['label'] as String, icon: cat['icon'] as IconData, color: color, isDesktop: isDesktop),
        );
      },
    );
  }
}

class _IconCell extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDesktop;

  const _IconCell({required this.label, required this.icon, required this.color, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isDesktop ? 88 : 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isDesktop ? 52 : 46,
            height: isDesktop ? 52 : 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isDesktop ? 24 : 21),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ── Today's Deals strip ─────────────────────────────────────────────────────

class HomeDealsSection extends StatelessWidget {
  final bool isDesktop;
  final double hp;
  final Future<List<Deal>> dealsFuture;

  const HomeDealsSection({
    super.key,
    required this.isDesktop,
    required this.hp,
    required this.dealsFuture,
  });

  @override
  Widget build(BuildContext context) {
    final outerPad = isDesktop ? hp + 12 : hp;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(outerPad, 20, outerPad, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: Text('DEALS', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2)),
              ),
              const SizedBox(width: 10),
              Text("Today's Deals",
                  style: GoogleFonts.outfit(fontSize: isDesktop ? 20 : 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              Text('Up to 55% off', style: GoogleFonts.outfit(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('See All →', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.accentBlue, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        SizedBox(
          height: isDesktop ? 200 : 180,
          child: FutureBuilder<List<Deal>>(
            future: dealsFuture,
            builder: (context, snapshot) {
              final deals = snapshot.data ?? Deal.fallbacks;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: outerPad),
                itemCount: deals.length,
                itemBuilder: (context, i) => _DealCard(deal: deals[i], isDesktop: isDesktop, isDark: isDark),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DealCard extends StatelessWidget {
  final Deal deal;
  final bool isDesktop;
  final bool isDark;

  const _DealCard({required this.deal, required this.isDesktop, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = deal.color;
    final off = deal.discountPercent;
    final sale = deal.salePrice;
    final original = deal.originalPrice;
    final label = deal.label;

    return Container(
      width: isDesktop ? 160 : 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: isDesktop ? 100 : 88,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Stack(
                children: [
                  deal.imageUrl != null
                      ? SafeNetworkImage(imageUrl: deal.imageUrl!, fit: BoxFit.cover)
                      : Center(child: Icon(Icons.checkroom_outlined, color: color, size: isDesktop ? 40 : 34)),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: Text('$off% OFF', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('₹$sale', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
                    const SizedBox(width: 6),
                    Text('₹$original', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section title ────────────────────────────────────────────────────────────

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const HomeSectionTitle({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveSizes.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? hp + 12 : hp, isDesktop ? 28 : 24, isDesktop ? hp + 12 : hp, isDesktop ? 14 : 12),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 5 : 4,
            height: isDesktop ? 26 : 20,
            decoration: BoxDecoration(gradient: AppColors.neonGradient, borderRadius: BorderRadius.circular(4)),
          ),
          SizedBox(width: isDesktop ? 12 : 10),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: isDesktop ? 20 : 15,
              fontWeight: FontWeight.w800,
              letterSpacing: isDesktop ? 1.4 : 1.1,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12, vertical: isDesktop ? 7 : 5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('See All →',
                  style: GoogleFonts.outfit(fontSize: isDesktop ? 13 : 12, fontWeight: FontWeight.w600, color: AppColors.accentBlue)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category chips list ──────────────────────────────────────────────────────

class HomeCategoryList extends StatelessWidget {
  final Future<List<Category>> future;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onRetry;

  const HomeCategoryList({
    super.key,
    required this.future,
    required this.selectedId,
    required this.onSelect,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 52, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return GestureDetector(
            onTap: onRetry,
            child: Container(
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.wifi_off, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Text('No internet — tap to retry', style: GoogleFonts.outfit(color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }
        return SizedBox(
          height: 52,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveSizes.horizontalPadding(context)),
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final cat = snapshot.data![i];
              final isSelected = selectedId == cat.id;
              return GestureDetector(
                onTap: () => onSelect(isSelected ? null : cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.neonGradient : null,
                    color: isSelected ? null : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: isSelected ? Colors.transparent
                          : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Text(cat.title,
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Featured products row ────────────────────────────────────────────────────

class HomeFeaturedProductsRow extends StatelessWidget {
  final Future<List<Product>> future;
  final bool isDesktop;
  final double hp;

  const HomeFeaturedProductsRow({super.key, required this.future, required this.isDesktop, required this.hp});

  @override
  Widget build(BuildContext context) {
    final cardW = isDesktop ? 200.0 : 160.0;
    final cardH = isDesktop ? 280.0 : 230.0;

    return FutureBuilder<List<Product>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(height: cardH, child: const Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;

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
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p, heroTag: tag), settings: RouteSettings(name: '/product/${p.slug}'))),
                child: Container(
                  width: cardW,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: cardH * 0.65,
                          width: double.infinity,
                          child: Stack(fit: StackFit.expand, children: [
                            Hero(
                              tag: tag,
                              child: Container(
                                color: AppColors.backgroundLight,
                                child: p.imageUrl != null
                                    ? SafeNetworkImage(imageUrl: p.imageUrl!, fit: BoxFit.cover)
                                    : const Icon(Icons.image_not_supported, size: 36),
                              ),
                            ),
                            Positioned(
                              top: 8, left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(gradient: AppColors.neonGradient, borderRadius: BorderRadius.circular(4)),
                                child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text('₹${p.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.accentBlue)),
                              const Spacer(),
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              Text(' 4.5', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                            ]),
                          ]),
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

