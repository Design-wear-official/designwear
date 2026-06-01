import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../presentation/styles/app_colors.dart';
import '../../models/product.dart';
import '../../presentation/utils/responsive_utils.dart';
import '../../presentation/widgets/safe_network_image.dart';
import '../product_detail_screen.dart';
import '../design_studio_screen.dart';

// ── Design Studio banner ─────────────────────────────────────────────────────

class HomeDesignStudioBanner extends StatelessWidget {
  const HomeDesignStudioBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveSizes.horizontalPadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DesignStudioScreen(), settings: const RouteSettings(name: '/design-studio'))),
      child: Container(
        margin: EdgeInsets.fromLTRB(isDesktop ? 8 : hp, 12, hp, 12),
        height: isDesktop ? 200 : ResponsiveSizes.bannerHeight(context),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1503342394128-c104d54dba01?q=80&w=2069&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: AppColors.backgroundLight),
                  placeholder: (_, __) => Container(color: AppColors.backgroundLight),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xCC8A2BE2), Color(0xCC00F0FF)],
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.brush_rounded, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text('DESIGN YOUR OWN',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: isDesktop ? 20 : 18, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text('Create your unique style',
                        style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
                      ),
                      child: Text('START CREATING',
                          style: GoogleFonts.outfit(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Trending sidebar ─────────────────────────────────────────────────────────

class HomeTrendingSection extends StatelessWidget {
  const HomeTrendingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveSizes.horizontalPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Live stats
        Container(
          margin: EdgeInsets.fromLTRB(8, 0, hp, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.purple.withOpacity(0.15), AppColors.accentBlue.withOpacity(0.1)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : AppColors.purple.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('1.2K', 'Orders Today', AppColors.accentBlue, context),
              Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.black12),
              _stat('38', 'New Designs', AppColors.purple, context),
              Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.black12),
              _stat('4.9★', 'Rating', AppColors.gold, context),
            ],
          ),
        ),
        // Trending + features card
        Container(
          margin: EdgeInsets.fromLTRB(8, 0, hp, 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
            boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.08), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.trending_up_rounded, color: AppColors.accentBlue, size: 16),
                ),
                const SizedBox(width: 10),
                Text('TRENDING NOW',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppColors.accentBlue)),
              ]),
              const SizedBox(height: 16),
              _trendItem('Graphic Tees', '#1', Icons.trending_up, AppColors.accentBlue, context),
              _trendItem('Hoodies', '#2', Icons.local_fire_department, Colors.orange, context),
              _trendItem('Polo Shirts', '#3', Icons.star, AppColors.gold, context),
              _trendItem('Tank Tops', '#4', Icons.bolt, AppColors.purple, context),
              const SizedBox(height: 18),
              Container(height: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
              const SizedBox(height: 16),
              Text('WHY CHOOSE US',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              const SizedBox(height: 12),
              _featureRow(Icons.local_shipping_outlined, 'Free shipping over ₹999', context),
              _featureRow(Icons.replay, '30-day returns', context),
              _featureRow(Icons.verified_outlined, 'Premium quality', context),
              _featureRow(Icons.support_agent, '24/7 support', context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(String val, String label, Color color, BuildContext ctx) => Column(
    children: [
      Text(val, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w500, color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6))),
    ],
  );

  Widget _trendItem(String label, String rank, IconData icon, Color color, BuildContext ctx) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(ctx).colorScheme.onSurface))),
      Text(rank, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]),
  );

  Widget _featureRow(IconData icon, String text, BuildContext ctx) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.accentBlue),
      const SizedBox(width: 10),
      Text(text, style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.75))),
    ]),
  );
}

// ── All Products grid ────────────────────────────────────────────────────────

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
          return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return GestureDetector(
            onTap: onRetry,
            child: Container(
              height: 200, margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withOpacity(0.3))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.wifi_off, color: Colors.orange, size: 40),
                const SizedBox(height: 12),
                Text('No internet connection', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                Text('Pull down to refresh or tap to retry', style: GoogleFonts.outfit(fontSize: 13, color: Colors.orange.shade600)),
              ]),
            ),
          );
        }

        final q = searchQuery.toLowerCase();
        final filtered = snapshot.data!.where((p) {
          final matchesCat = selectedCategoryId == null || p.categoryId == selectedCategoryId;
          final matchesQ = q.isEmpty || p.title.toLowerCase().contains(q) || p.description.toLowerCase().contains(q);
          return matchesCat && matchesQ;
        }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(children: [
              Icon(Icons.search_off_rounded, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(q.isNotEmpty ? 'No results for "$q"' : 'No products in this category',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onClearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(gradient: AppColors.neonGradient, borderRadius: BorderRadius.circular(20)),
                  child: Text('Clear filters', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: LayoutBuilder(builder: (context, constraints) {
            final isDesktop = ResponsiveUtils.isDesktop(context);
            final hPad = ResponsiveSizes.horizontalPadding(context);
            final outerPad = isDesktop ? hPad + 12 : hPad;
            final availableW = constraints.maxWidth - outerPad * 2;
            final cols = (availableW / 250).floor().clamp(2, 6);
            const spacing = 16.0;
            final cardW = (availableW - spacing * (cols - 1)) / cols;
            final cardH = cardW * 1.55;
            final borderR = isDesktop ? 18.0 : 14.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(outerPad, 8, outerPad, 8),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: filtered.map((p) {
                  final tag = 'grid_${p.id}';
                  return SizedBox(
                    width: cardW, height: cardH,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p, heroTag: tag), settings: RouteSettings(name: '/product/${p.slug}'))),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(borderR),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 4))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(borderR),
                          child: Stack(children: [
                            Positioned.fill(child: Hero(
                              tag: tag,
                              child: Container(
                                color: AppColors.backgroundLight,
                                child: p.imageUrl != null
                                    ? SafeNetworkImage(imageUrl: p.imageUrl!, fit: BoxFit.cover)
                                    : Icon(Icons.image_not_supported, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 36),
                              ),
                            )),
                            Positioned(top: 10, right: 10,
                              child: Container(padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                  child: const Icon(Icons.favorite_border, color: Colors.white, size: 14))),
                            Positioned(bottom: 0, left: 0, right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                      colors: [Colors.black.withOpacity(0.9), Colors.transparent]),
                                ),
                                padding: EdgeInsets.all(cols >= 4 ? 14 : 12),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                    Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(fontSize: cols >= 4 ? 13 : 12, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3)),
                                    const SizedBox(height: 4),
                                    Text('₹${p.price.toStringAsFixed(0)}',
                                        style: GoogleFonts.outfit(fontSize: cols >= 4 ? 14 : 13, fontWeight: FontWeight.w900, color: AppColors.accentBlue)),
                                  ])),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: cols >= 4 ? 10 : 8, vertical: cols >= 4 ? 7 : 6),
                                    decoration: BoxDecoration(gradient: AppColors.neonGradient, borderRadius: BorderRadius.circular(10)),
                                    child: Icon(Icons.add_shopping_cart, color: Colors.white, size: cols >= 4 ? 15 : 13),
                                  ),
                                ]),
                              )),
                          ]),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        );
      },
    );
  }
}

