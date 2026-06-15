import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/presentation/widgets/garment_tile.dart';

/// Feed layout modes matching demo `.feed.layout-grid` and `.feed.layout-detail`.
enum FeedLayout { grid, detail }

/// Static community design data model used for the feed.
class FeedDesign {
  final String title;
  final String handle;
  final String avatarInitials;
  final Color garmentColor;
  final String? remixedFrom;
  final String version;
  final String likes;
  final String remixes;
  final Color avatarGradientStart;
  final Color avatarGradientEnd;
  final String? artText;

  const FeedDesign({
    required this.title,
    required this.handle,
    required this.avatarInitials,
    required this.garmentColor,
    this.remixedFrom,
    required this.version,
    required this.likes,
    required this.remixes,
    required this.avatarGradientStart,
    required this.avatarGradientEnd,
    this.artText,
  });

  static const List<FeedDesign> samples = [
    FeedDesign(
      title: 'Petrichor Tee',
      handle: '@aanya',
      avatarInitials: 'Aa',
      garmentColor: Color(0xFF2C5F5A),
      remixedFrom: '@kabir',
      version: 'v3',
      likes: '3.1k',
      remixes: '412',
      avatarGradientStart: Color(0xFFe0825a),
      avatarGradientEnd: Color(0xFFe2a33c),
      artText: 'PETRICHOR',
    ),
    FeedDesign(
      title: 'After the Rain',
      handle: '@kabir',
      avatarInitials: 'Kb',
      garmentColor: Color(0xFF3A4668),
      version: 'v2',
      likes: '1.8k',
      remixes: '204',
      avatarGradientStart: Color(0xFF5a6cff),
      avatarGradientEnd: Color(0xFF9b6cff),
    ),
    FeedDesign(
      title: 'Static Type',
      handle: '@dev',
      avatarInitials: 'Dv',
      garmentColor: Color(0xFF2B2E33),
      remixedFrom: '@aanya',
      version: 'v1',
      likes: '982',
      remixes: '77',
      avatarGradientStart: Color(0xFF3aa17e),
      avatarGradientEnd: Color(0xFF7ec59f),
    ),
    FeedDesign(
      title: 'Clay Court',
      handle: '@rhea',
      avatarInitials: 'Rh',
      garmentColor: Color(0xFFB65D3C),
      version: 'v4',
      likes: '2.4k',
      remixes: '318',
      avatarGradientStart: Color(0xFFe0825a),
      avatarGradientEnd: Color(0xFFc9a227),
    ),
    FeedDesign(
      title: 'Field Notes',
      handle: '@imran',
      avatarInitials: 'Im',
      garmentColor: Color(0xFF7E8B6B),
      remixedFrom: '@maya',
      version: 'v2',
      likes: '1.1k',
      remixes: '140',
      avatarGradientStart: Color(0xFF6b8f6b),
      avatarGradientEnd: Color(0xFFaac0a0),
    ),
    FeedDesign(
      title: 'Midnight Mono',
      handle: '@maya',
      avatarInitials: 'My',
      garmentColor: Color(0xFF1C2541),
      version: 'v1',
      likes: '4.6k',
      remixes: '690',
      avatarGradientStart: Color(0xFF3a4668),
      avatarGradientEnd: Color(0xFF7a86b8),
    ),
  ];
}

/// The main feed grid — supports masonry-grid (columns) and detail-list layouts.
class HomeFeedGrid extends StatelessWidget {
  final FeedLayout layout;
  final VoidCallback? onCardTap;
  final VoidCallback? onRemixTap;

  const HomeFeedGrid({
    super.key,
    this.layout = FeedLayout.grid,
    this.onCardTap,
    this.onRemixTap,
  });

  @override
  Widget build(BuildContext context) {
    if (layout == FeedLayout.detail) {
      return _buildDetailList(context);
    }
    return _buildMasonryGrid(context);
  }

  /// Masonry-style multi-column grid
  Widget _buildMasonryGrid(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final cols = isDesktop ? 3 : (isTablet ? 2 : 1);

    if (cols == 1) {
      return Column(
        children: FeedDesign.samples
            .map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FeedCard(design: d, onTap: onCardTap, onRemixTap: onRemixTap),
                ))
            .toList(),
      );
    }

    // Multi-column masonry — distribute items round-robin
    final columns = List.generate(cols, (_) => <FeedDesign>[]);
    for (int i = 0; i < FeedDesign.samples.length; i++) {
      columns[i % cols].add(FeedDesign.samples[i]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(cols, (col) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: col == 0 ? 0 : 7,
              right: col == cols - 1 ? 0 : 7,
            ),
            child: Column(
              children: columns[col]
                  .map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: FeedCard(
                          design: d,
                          onTap: onCardTap,
                          onRemixTap: onRemixTap,
                        ),
                      ))
                  .toList(),
            ),
          ),
        );
      }),
    );
  }

  /// Detail-list layout — larger cards stacked vertically
  Widget _buildDetailList(BuildContext context) {
    return Column(
      children: FeedDesign.samples
          .map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: FeedCard(
                  design: d,
                  layout: FeedLayout.detail,
                  onTap: onCardTap,
                  onRemixTap: onRemixTap,
                ),
              ))
          .toList(),
    );
  }
}

/// A single feed card matching the demo `.fcard` element.
class FeedCard extends StatefulWidget {
  final FeedDesign design;
  final FeedLayout layout;
  final VoidCallback? onTap;
  final VoidCallback? onRemixTap;

  const FeedCard({
    super.key,
    required this.design,
    this.layout = FeedLayout.grid,
    this.onTap,
    this.onRemixTap,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final isDetail = widget.layout == FeedLayout.detail;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hair),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hovered ? 0.22 : 0.08),
                blurRadius: _hovered ? 24 : 12,
                offset: Offset(0, _hovered ? 8 : 3),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: isDetail
              ? _buildDetailCard(isDark, card, hair, ink)
              : _buildGridCard(isDark, card, hair, ink),
        ),
      ),
    );
  }

  Widget _buildGridCard(bool isDark, Color card, Color hair, Color ink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhotoArea(isDark, detail: false),
        _buildCardBody(isDark, hair, ink),
      ],
    );
  }

  Widget _buildDetailCard(bool isDark, Color card, Color hair, Color ink) {
    final isTabletPlus = MediaQuery.sizeOf(context).width >= 600;
    if (isTabletPlus) {
      return Row(
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.42,
            child: _buildPhotoArea(isDark, detail: true),
          ),
          Container(width: 1, height: 220, color: hair),
          Expanded(child: _buildCardBody(isDark, hair, ink, detail: true)),
        ],
      );
    }
    return Column(children: [
      _buildPhotoArea(isDark, detail: false),
      _buildCardBody(isDark, hair, ink, detail: true),
    ]);
  }

  Widget _buildPhotoArea(bool isDark, {required bool detail}) {
    final d = widget.design;

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: GarmentTile(
            garmentColor: d.garmentColor,
            showArt: d.artText != null,
            artText: d.artText,
            borderRadius: BorderRadius.zero,
          ),
        ),

        // Provenance badge (from @user)
        if (d.remixedFrom != null)
          Positioned(
            top: 10, left: 10,
            child: _ProvenanceBadge(
              initials: d.avatarInitials,
              from: d.remixedFrom!,
              gradStart: d.avatarGradientStart,
              gradEnd: d.avatarGradientEnd,
            ),
          ),

        // Version badge
        Positioned(
          top: 10, right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.inkDark : AppColors.inkLight,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '⑂ ${d.version}',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w700,
                fontSize: 9.5,
                color: isDark ? AppColors.inkLight : AppColors.inkDark,
                letterSpacing: 0.04,
              ),
            ),
          ),
        ),

        // Remix overlay on hover
        AnimatedOpacity(
          opacity: _hovered ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                ),
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: widget.onRemixTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.marigold,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.marigold.withOpacity(0.7),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.fork_right, color: Color(0xFF6F4710), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'Remix',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.marigoldInk,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardBody(bool isDark, Color hair, Color ink, {bool detail = false}) {
    final d = widget.design;

    return Padding(
      padding: EdgeInsets.all(detail ? 18 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            d.title,
            style: GoogleFonts.inter(
              fontSize: detail ? 18 : 14,
              fontWeight: FontWeight.w700,
              color: ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 9),

          // Creator row
          Row(children: [
            _AvatarCircle(
              initials: d.avatarInitials,
              gradStart: d.avatarGradientStart,
              gradEnd: d.avatarGradientEnd,
              size: 20,
            ),
            const SizedBox(width: 7),
            Text(
              d.handle,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: ink,
              ),
            ),
          ]),

          const SizedBox(height: 11),
          Container(height: 1, color: hair),
          const SizedBox(height: 11),

          // Stats
          Row(children: [
            _Stat(icon: Icons.favorite, value: d.likes, color: AppColors.like),
            const SizedBox(width: 14),
            _Stat(icon: Icons.fork_right, value: d.remixes, color: AppColors.marigold),
          ]),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _ProvenanceBadge extends StatelessWidget {
  final String initials;
  final String from;
  final Color gradStart;
  final Color gradEnd;

  const _ProvenanceBadge({
    required this.initials,
    required this.from,
    required this.gradStart,
    required this.gradEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.paperDark.withOpacity(0.92) : AppColors.paperLight.withOpacity(0.92);
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 9, 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: hair),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _AvatarCircle(initials: initials, gradStart: gradStart, gradEnd: gradEnd, size: 18),
        const SizedBox(width: 6),
        Text(
          from,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontWeight: FontWeight.w700,
            fontSize: 10,
            color: AppColors.stone,
          ),
        ),
      ]),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String initials;
  final Color gradStart;
  final Color gradEnd;
  final double size;

  const _AvatarCircle({
    required this.initials,
    required this.gradStart,
    required this.gradEnd,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [gradStart, gradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.archivo(
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _Stat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 5),
      Text(
        value,
        style: TextStyle(
          fontFamily: 'SpaceMono',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppColors.stone,
        ),
      ),
    ]);
  }
}
