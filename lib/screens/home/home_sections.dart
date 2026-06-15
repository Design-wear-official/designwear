import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/widgets/widgets.dart';
import 'package:designwear/screens/design_studio_screen.dart';
import 'package:designwear/screens/design_detail_screen.dart';
import 'home_constants.dart';

// ── Feed filter tab bar ───────────────────────────────────────────────────────

/// Horizontal scrollable filter tabs matching demo `.tabs` element.
class HomeFeedFilterTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabTap;

  const HomeFeedFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabTap,
  });

  static const _tabs = [
    'Trending', 'New', 'Following', 'Challenges',
    'Tees', 'Typographic', 'Minimal',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTabTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? ink : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _tabs[i],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? card : AppColors.stone,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Category icon quick-access row ───────────────────────────────────────────

class HomeCategoryIconRow extends StatelessWidget {
  final bool isDesktop;
  final double hp;
  final ValueChanged<int> onCategoryTap;
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
    final useSanity = quickLinks.isNotEmpty;

    return SizedBox(
      height: isDesktop ? 90 : 82,
      child: useSanity
          ? _buildFromSanity(context)
          : _buildFromConstants(context),
    );
  }

  Widget _buildFromSanity(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? hp + 12 : hp),
      itemCount: quickLinks.length,
      itemBuilder: (context, i) {
        final link = quickLinks[i];
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
          child: _IconCell(
            label: link.label,
            icon: link.icon,
            color: link.color,
            isDesktop: isDesktop,
          ),
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
              const labelToTab = {
                'Trending': 0, 'New In': 1, 'Sale': 2,
                'T-Shirts': 3, 'Hoodies': 4, 'Polo': 5,
              };
              final idx = labelToTab[cat['label'] as String];
              if (idx != null) onCategoryTap(idx);
            }
          },
          child: _IconCell(
            label: cat['label'] as String,
            icon: cat['icon'] as IconData,
            color: color,
            isDesktop: isDesktop,
          ),
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

  const _IconCell({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;

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
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ink.withOpacity(0.7),
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
        isDesktop ? hp + 12 : hp, isDesktop ? 28 : 24,
        isDesktop ? hp + 12 : hp, isDesktop ? 14 : 12,
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 5 : 4,
            height: isDesktop ? 26 : 20,
            decoration: BoxDecoration(
              gradient: AppColors.neonGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 10),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.archivo(
              fontSize: isDesktop ? 20 : 15,
              fontWeight: FontWeight.w800,
              letterSpacing: isDesktop ? 1.4 : 1.1,
              color: ink,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 12,
                vertical: isDesktop ? 7 : 5,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.05),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;

    return FutureBuilder<List<Category>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 52,
            child: Center(child: CircularProgressIndicator()),
          );
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
                Text(
                  'No internet — tap to retry',
                  style: GoogleFonts.inter(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          );
        }
        return SizedBox(
          height: 52,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSizes.horizontalPadding(context),
            ),
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
                    color: isSelected ? ink : card,
                    border: Border.all(color: isSelected ? Colors.transparent : hair),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isSelected
                        ? [BoxShadow(color: ink.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Text(
                    cat.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isDark ? AppColors.inkLight : AppColors.inkDark)
                          : ink,
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

// ── Deals section ─────────────────────────────────────────────────────────────

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outerPad = isDesktop ? hp + 12 : hp;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(outerPad, 20, outerPad, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEALS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Today's Deals",
                style: GoogleFonts.archivo(
                  fontSize: isDesktop ? 20 : 16,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const Spacer(),
              Text(
                'Up to 55% off',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'See All →',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.marigold,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                itemBuilder: (context, i) =>
                    _DealCard(deal: deals[i], isDesktop: isDesktop, isDark: isDark),
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
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;

    return Container(
      width: isDesktop ? 160 : 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hair),
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
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                deal.imageUrl != null
                    ? SafeNetworkImage(imageUrl: deal.imageUrl!, fit: BoxFit.cover)
                    : Center(
                        child: Icon(Icons.checkroom_outlined,
                            color: color, size: isDesktop ? 40 : 34)),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${deal.discountPercent}% OFF',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                deal.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Text(
                  '₹${deal.salePrice}',
                  style: GoogleFonts.archivo(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '₹${deal.originalPrice}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

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
          return SizedBox(height: cardH, child: const Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

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
                    builder: (_) => _ProductDetailRoute(product: p, heroTag: tag),
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
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(
                        height: cardH * 0.65,
                        width: double.infinity,
                        child: Stack(fit: StackFit.expand, children: [
                          Hero(
                            tag: tag,
                            child: Container(
                              color: isDark ? AppColors.backgroundLight : const Color(0xFFF5F4F0),
                              child: p.imageUrl != null
                                  ? SafeNetworkImage(imageUrl: p.imageUrl!, fit: BoxFit.cover)
                                  : const Icon(Icons.image_not_supported, size: 36),
                            ),
                          ),
                          Positioned(
                            top: 8, left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.marigold,
                                borderRadius: BorderRadius.circular(4),
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
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                          Row(children: [
                            Text(
                              '₹${p.price.toStringAsFixed(0)}',
                              style: GoogleFonts.archivo(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.marigold,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            Text(
                              ' 4.5',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.stone,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ]),
                        ]),
                      ),
                    ]),
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

// Lazy product detail helper to avoid circular imports
class _ProductDetailRoute extends StatelessWidget {
  final Product product;
  final String heroTag;
  const _ProductDetailRoute({required this.product, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    // Use named route to avoid import cycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _ProductDetailLoader(product: product, heroTag: heroTag),
        ),
      );
    });
    return const SizedBox.shrink();
  }
}

class _ProductDetailLoader extends StatelessWidget {
  final Product product;
  final String heroTag;
  const _ProductDetailLoader({required this.product, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return DesignDetailScreen(product: product);
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
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.orange.shade600),
                ),
              ]),
            ),
          );
        }

        final q = searchQuery.toLowerCase();
        final filtered = snapshot.data!.where((p) {
          final matchesCat = selectedCategoryId == null || p.categoryId == selectedCategoryId;
          final matchesQ = q.isEmpty ||
              p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q);
          return matchesCat && matchesQ;
        }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(children: [
              Icon(Icons.search_off_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(
                q.isNotEmpty ? 'No results for "$q"' : 'No products in this category',
                style: GoogleFonts.archivo(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onClearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            ]),
          );
        }

        return LayoutBuilder(builder: (context, constraints) {
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
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => _ProductDetailLoaderDirect(product: p, heroTag: tag),
                      settings: RouteSettings(name: '/product/${p.slug}'),
                    )),
                    child: Container(
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 14),
                        border: Border.all(color: hair),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isDesktop ? 18 : 14),
                        child: Stack(children: [
                          Positioned.fill(
                            child: Hero(
                              tag: tag,
                              child: Container(
                                color: isDark ? AppColors.backgroundLight : const Color(0xFFF5F4F0),
                                child: p.imageUrl != null
                                    ? SafeNetworkImage(imageUrl: p.imageUrl!, fit: BoxFit.cover)
                                    : Icon(Icons.image_not_supported,
                                        color: ink.withOpacity(0.4), size: 36),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10, right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_border, color: Colors.white, size: 14),
                            ),
                          ),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black.withOpacity(0.88), Colors.transparent],
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.marigold,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.add_shopping_cart,
                                        color: AppColors.marigoldInk, size: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        });
      },
    );
  }
}

class _ProductDetailLoaderDirect extends StatelessWidget {
  final Product product;
  final String heroTag;
  const _ProductDetailLoaderDirect({required this.product, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return DesignDetailScreen(product: product);
  }
}
