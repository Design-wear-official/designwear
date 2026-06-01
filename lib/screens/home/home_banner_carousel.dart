import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../presentation/styles/app_colors.dart';
import '../../models/banner.dart';
import '../design_studio_screen.dart';

class HomeBannerCarousel extends StatelessWidget {
  final PageController controller;
  final int currentPage;
  final bool isDesktop;
  final double hp;
  final ScrollController scrollController;
  final ValueChanged<int> onPageChanged;
  final List<HomeBanner> banners;

  const HomeBannerCarousel({
    super.key,
    required this.controller,
    required this.currentPage,
    required this.isDesktop,
    required this.hp,
    required this.scrollController,
    required this.onPageChanged,
    required this.banners,
  });

  @override
  Widget build(BuildContext context) {
    final bannerH = isDesktop ? 400.0 : 210.0;
    final margin = isDesktop
        ? EdgeInsets.fromLTRB(hp + 12, 14, 8, 0)
        : EdgeInsets.zero;

    return Column(
      children: [
        Container(
          margin: margin,
          height: bannerH,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isDesktop ? 24 : 0),
            child: PageView.builder(
              controller: controller,
              onPageChanged: onPageChanged,
              itemCount: banners.length,
              itemBuilder: (ctx, i) => _BannerSlide(
                banner: banners[i],
                isDesktop: isDesktop,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            final active = currentPage == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: active ? AppColors.neonGradient : null,
                color: active ? null : Colors.grey.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final HomeBanner banner;
  final bool isDesktop;
  final ScrollController scrollController;

  const _BannerSlide({
    required this.banner,
    required this.isDesktop,
    required this.scrollController,
  });

  Color get _ctaColor {
    if (banner.ctaColor == 'blue') return AppColors.accentBlue;
    if (banner.ctaColor == 'orange') return Colors.orange;
    return AppColors.purple;
  }

  void _onCtaTap(BuildContext context) {
    if (banner.ctaAction == 'design') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const DesignStudioScreen(),
        settings: const RouteSettings(name: '/design-studio'),
      ));
    } else {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent * 0.35,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: banner.imageUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(color: AppColors.backgroundLight),
          placeholder: (_, __) => Container(color: AppColors.backgroundLight),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.0, 0.55, 1.0],
              colors: [Colors.black.withOpacity(0.92), Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.05)],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(isDesktop ? 36 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _ctaColor.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                child: Text(banner.badge,
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.white)),
              ),
              SizedBox(height: isDesktop ? 14 : 8),
              Text(banner.title,
                  style: GoogleFonts.outfit(fontSize: isDesktop ? 44 : 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
              SizedBox(height: isDesktop ? 10 : 6),
              Text(banner.subtitle,
                  style: GoogleFonts.outfit(fontSize: isDesktop ? 15 : 12, color: Colors.white.withOpacity(0.75))),
              SizedBox(height: isDesktop ? 24 : 14),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _onCtaTap(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 22, vertical: isDesktop ? 14 : 10),
                      decoration: BoxDecoration(
                        color: _ctaColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: _ctaColor.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 5))],
                      ),
                      child: Text(banner.ctaLabel,
                          style: GoogleFonts.outfit(fontSize: isDesktop ? 14 : 12, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.white)),
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => scrollController.animateTo(
                        scrollController.position.maxScrollExtent * 0.35,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(border: Border.all(color: Colors.white54, width: 1.5), borderRadius: BorderRadius.circular(30)),
                        child: Text('EXPLORE', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.white)),
                      ),
                    ),
                    const Spacer(),
                    _StatChip('50K+', 'Customers'),
                    const SizedBox(width: 8),
                    _StatChip('1200+', 'Designs'),
                    const SizedBox(width: 8),
                    _StatChip('4.9★', 'Rating'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }
}

