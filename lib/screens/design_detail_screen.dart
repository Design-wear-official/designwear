import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/presentation/widgets/widgets.dart';
import 'design_studio_screen.dart';
import 'virtual_tryon_screen.dart';

class DesignDetailScreen extends StatefulWidget {
  final Product? product;
  const DesignDetailScreen({super.key, this.product});

  @override
  State<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends State<DesignDetailScreen> {
  bool _isFollowing = false;
  bool _isLiked = false;
  late int _likeCount;
  late final Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product ?? Product(
      id: "petrichor-tee-001",
      title: "Petrichor Tee",
      slug: "petrichor-tee",
      description: "A community design remixed from the DesignWear feed.",
      price: 9.99,
      categoryId: "custom",
      stockStatus: 'inStock',
    );
    _likeCount = _product.likeCount;
  }

  // ── Derived helpers that fall back to defaults when Sanity field is absent ──

  String get _creatorName => _product.creatorName ?? 'Unknown';
  String get _creatorHandle {
    final h = _product.creatorHandle;
    if (h == null || h.isEmpty) return '@unknown';
    return h.startsWith('@') ? h : '@$h';
  }

  String get _followerLabel {
    final n = _product.creatorFollowerCount;
    if (n == 0) return '';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k followers';
    return '$n followers';
  }

  String? get _provenanceBadge {
    final h = _product.remixedFromHandle;
    final v = _product.remixedFromVersion;
    if (h == null || h.isEmpty) return null;
    return 'Remixed from $h${v != null && v.isNotEmpty ? ' · $v' : ''}';
  }

  Color get _garmentColor {
    final hex = _product.garmentBaseColor;
    if (hex == null) return const Color(0xFF2C5F5A);
    final clean = hex.replaceAll('#', '');
    return Color(int.tryParse('FF$clean', radix: 16) ?? 0xFF2C5F5A);
  }

  String get _artText {
    final a = _product.artText;
    if (a != null && a.isNotEmpty) return a;
    final t = _product.title;
    if (t.isNotEmpty) return t.toUpperCase();
    return 'DESIGN';
  }

  GarmentShape get _garmentShape {
    switch (_product.productType?.toLowerCase()) {
      case 'hoodie':
        return GarmentShape.hoodie;
      case 'polo':
        return GarmentShape.polo;
      case 'cap':
        return GarmentShape.cap;
      case 'totebag':
        return GarmentShape.totebag;
      default:
        return GarmentShape.tshirt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leadingWidth: 90,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, size: 14, color: cs.onSurface),
            label: Text(
              'Feed',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: cs.onSurface,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF151824) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: hair),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DESIGN',
              style: GoogleFonts.archivo(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: cs.onSurface,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'WEAR',
              style: GoogleFonts.archivo(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.marigold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: hair),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isLiked = !_isLiked;
                  _likeCount += _isLiked ? 1 : -1;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isLiked ? 'Added to saved designs!' : 'Removed from saved designs!',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              icon: Icon(
                _isLiked ? Icons.bookmark : Icons.bookmark_border_outlined,
                color: _isLiked ? AppColors.marigold : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSizes.horizontalPadding(context),
                  vertical: 24,
                ),
                child: isMobile ? _buildMobileLayout() : _buildDesktopTabletLayout(),
              ),
            ),
            if (isMobile) _buildMobileBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Mobile 1-Column Layout ──────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Image
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.hairDark
                    : AppColors.hairLight,
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: _product.imageUrl != null
                  ? SafeNetworkImage(imageUrl: _product.imageUrl!, fit: BoxFit.cover)
                  : GarmentTile(
                      garmentColor: _garmentColor,
                      shape: _garmentShape,
                      showArt: true,
                      artText: _artText,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Virtual Try-On Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VirtualTryOnScreen(product: _product),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome, color: AppColors.marigold),
            label: Text(
              'Try It On Virtually ✨',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.marigoldInk,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(
                color: AppColors.marigold,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoDetails(),
        const Divider(height: 40),
        _buildLineageSection(),
        const Divider(height: 40),
        _buildRemixesSection(),
      ],
    );
  }

  // ── Tablet / Desktop 2-Column Layout ────────────────────────────────────────
  Widget _buildDesktopTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sticky-like hero
            Expanded(
              flex: 11,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.hairDark
                          : AppColors.hairLight,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    child: _product.imageUrl != null
                        ? SafeNetworkImage(imageUrl: _product.imageUrl!, fit: BoxFit.cover)
                        : GarmentTile(
                            garmentColor: _garmentColor,
                            shape: _garmentShape,
                            showArt: true,
                            artText: _artText,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 32),
            // Right info
            Expanded(
              flex: 9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoDetails(),
                  const SizedBox(height: 24),
                  // CTA block directly visible on tablet/desktop (replaces bottom bar)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToStudio,
                          icon: const Icon(Icons.fork_right, size: 18),
                          label: const Text('Remix this design'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.marigold,
                            foregroundColor: const Color(0xFF6F4710),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VirtualTryOnScreen(product: _product),
                              ),
                            );
                          },
                          icon: const Icon(Icons.auto_awesome, color: AppColors.marigold),
                          label: const Text('Try It On Virtually ✨'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                            side: const BorderSide(
                              color: AppColors.marigold,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _wearAsIs,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                            side: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.hairDark
                                  : AppColors.hairLight,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text('Wear it as-is — ₹${_product.price.toStringAsFixed(0)}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 48),
        _buildLineageSection(),
        const Divider(height: 48),
        _buildRemixesSection(),
      ],
    );
  }

  // ── Info details section ───────────────────────────────────────────────────
  Widget _buildInfoDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _product.title,
          style: GoogleFonts.archivo(
            fontWeight: FontWeight.w800,
            fontSize: ResponsiveUtils.getResponsiveValue<double>(
              context,
              mobile: 26,
              tablet: 28,
              desktop: 32,
            ),
            letterSpacing: -0.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),

        // Creator Row
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFE0825A), Color(0xFFE2A33C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  _creatorName.isNotEmpty ? _creatorName[0].toUpperCase() : '?',
                  style: GoogleFonts.archivo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _creatorName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _followerLabel.isNotEmpty
                      ? '$_creatorHandle · $_followerLabel'
                      : _creatorHandle,
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: AppColors.stone,
                  ),
                ),
              ],
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isFollowing = !_isFollowing;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(
                _isFollowing ? 'Following' : 'Follow',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        if (_product.description.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            _product.description,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Provenance Badge (only shown when remixed from another creator)
        if (_provenanceBadge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF261D15) : const Color(0xFFF4E6CD),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark ? const Color(0xFF4C3B24) : const Color(0xFFECD6A8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fork_right,
                  size: 13,
                  color: isDark ? const Color(0xFFFFE9C2) : const Color(0xFF6F4710),
                ),
                const SizedBox(width: 6),
                Text(
                  _provenanceBadge!,
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isDark ? const Color(0xFFFFE9C2) : const Color(0xFF6F4710),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Stats Row
        Row(
          children: [
            _buildStatItem(
              icon: Icons.favorite,
              value: _likeCount.toString(),
              color: AppColors.like,
            ),
            const SizedBox(width: 20),
            _buildStatItem(
              icon: Icons.fork_right,
              value: _product.remixCount.toString(),
              color: AppColors.marigold,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tags
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _product.tags.isNotEmpty
              ? _product.tags.map((t) => _buildTag('#$t')).toList()
              : [
                  _buildTag('#monsoon'),
                  _buildTag('#typographic'),
                  _buildTag('#teal'),
                ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppColors.stone,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? AppColors.hairDark : AppColors.hairLight,
        ),
      ),
      child: Text(
        tag,
        style: GoogleFonts.spaceMono(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  // ── Lineage Section ────────────────────────────────────────────────────────
  Widget _buildLineageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lineage',
          style: GoogleFonts.archivo(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _product.lineage.isNotEmpty
              ? 'Every remix keeps its thread. This design is ${_product.lineage.length} fork${_product.lineage.length == 1 ? '' : 's'} deep.'
              : 'Every remix keeps its thread.',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.stone,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildLineageRow(),
        ),
      ],
    );
  }

  Widget _buildLineageRow() {
    final lineage = _product.lineage;
    if (lineage.isEmpty) {
      // Lineage not yet filled in Sanity — show current design as the origin
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LineageNode(
            garmentColor: _garmentColor,
            handle: _creatorHandle.isNotEmpty ? _creatorHandle : '@creator',
            version: 'origin · v0',
            isCurrent: true,
            artText: _artText,
          ),
        ],
      );
    }
    final nodes = <Widget>[];
    for (int i = 0; i < lineage.length; i++) {
      final entry = lineage[i];
      final hex = entry['baseColor'] ?? '';
      final clean = hex.replaceAll('#', '');
      final color = Color(int.tryParse('FF$clean', radix: 16) ?? 0xFF1C2541);
      nodes.add(LineageNode(
        garmentColor: color,
        handle: entry['handle'] ?? '',
        version: entry['version'] ?? '',
        artText: entry['artText'],
      ));
      nodes.add(const LineageStitch());
    }
    // Current design is always the last node
    nodes.add(LineageNode(
      garmentColor: _garmentColor,
      handle: _creatorHandle,
      version: 'this design',
      isCurrent: true,
      artText: _artText,
    ));
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: nodes);
  }

  // ── Remixes Section ────────────────────────────────────────────────────────
  Widget _buildRemixesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remixCount = _product.remixCount;

    // Build cards from lineage; no fake placeholders
    final List<Map<String, dynamic>> remixes = _product.lineage
        .map((e) {
          final hex = (e['baseColor'] ?? '').replaceAll('#', '');
          return <String, dynamic>{
            'handle': e['handle'] ?? '',
            'color': Color(int.tryParse('FF$hex', radix: 16) ?? 0xFF1C2541),
          };
        })
        .where((e) => (e['handle'] as String).isNotEmpty)
        .toList();

    final totalLabel = '$remixCount total';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: [
            Text(
              'Remixes',
              style: GoogleFonts.archivo(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              totalLabel,
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: AppColors.stone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (remixes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.hairDark : AppColors.hairLight,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.fork_right, size: 28, color: AppColors.stone),
                const SizedBox(height: 8),
                Text(
                  'No remixes yet — be the first!',
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.stone),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: remixes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveUtils.isMobile(context) ? 2 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final remix = remixes[index];
              final handle = remix['handle'] as String;
              final color = remix['color'] as Color;

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  border: Border.all(
                    color: isDark ? AppColors.hairDark : AppColors.hairLight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          topRight: Radius.circular(11),
                        ),
                        child: GarmentTile(
                          garmentColor: color,
                          shape: _garmentShape,
                          showArt: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(9),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueGrey,
                            ),
                            child: Center(
                              child: Text(
                                handle.replaceFirst('@', '').isNotEmpty
                                    ? handle.replaceFirst('@', '')[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              handle,
                              style: GoogleFonts.spaceMono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ── Mobile Bottom Bar ──────────────────────────────────────────────────────
  Widget _buildMobileBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0F16).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: hair)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _navigateToStudio,
              icon: const Icon(Icons.fork_right, size: 16),
              label: const Text('Remix this'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.marigold,
                foregroundColor: const Color(0xFF6F4710),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: _wearAsIs,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              side: BorderSide(color: hair, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Wear it'),
          ),
        ],
      ),
    );
  }

  // ── Core Action Triggers ───────────────────────────────────────────────────
  void _navigateToStudio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DesignStudioScreen(remixSource: _product),
      ),
    );
  }

  void _wearAsIs() {
    context.read<CartService>().addToCart(_product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_product.title} added to cart!')),
    );
  }
}
