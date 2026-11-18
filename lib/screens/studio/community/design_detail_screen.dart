import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/commerce.dart';
import '../../../models/design.dart';
import '../../../models/custom_design.dart' show CustomDesign;
import '../../../services/shop/cart_service.dart';
import '../../../services/community/community_service.dart';
import '../../account/auth_screens.dart';
import '../../home/home_screen.dart' show formatPrice;
import '../shared/design_preview.dart';
import '../editor/design_studio_screen.dart';
import 'share_design_sheet.dart';
import 'share_links.dart';

class DesignDetailScreen extends StatefulWidget {
  const DesignDetailScreen({super.key, required this.design});
  final CommunityDesign design;
  @override
  State<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends State<DesignDetailScreen> {
  late CommunityDesign _design = widget.design;
  bool _back = false;

  /// The size the creator chose in the studio, if any, else M.
  late String _size = () {
    final s = widget.design.designJson?['size'];
    return s is String && CustomDesign.sizes.contains(s) ? s : 'M';
  }();

  /// Public designs and my own can be liked, remixed and bought; one shared with me only when its owner allows copies.
  bool get _canUse => _design.mine || _design.published || _design.allowRemix;

  Future<void> _refresh() async {
    final service = context.read<CommunityService?>();
    if (service == null) return;
    try {
      final next = await service.get(_design.id, token: _design.accessToken);
      if (mounted) setState(() => _design = next);
    } catch (_) {}
  }

  Future<void> _like() async {
    if (!await requireSignIn(context) || !mounted) return;
    try {
      final (liked, count) = await context
          .read<CommunityService?>()!
          .toggleLike(_design.id);
      setState(() => _design = _design.withLike(liked, count));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _buy() async {
    if (!await requireSignIn(context) || !mounted) return;
    context.read<CartService>().add(
      CartLine(
        productId: 'design:${_design.id}',
        title: '${_design.name} (${_design.garment})',
        unitPrice: _design.price,
        size: _size,
        designId: _design.id,
      ),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Added to cart')));
  }

  @override
  Widget build(BuildContext context) {
    final d = _design;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(d.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Try it on',
            icon: const Icon(Icons.checkroom_outlined),
            onPressed: () => openTryOn(context, d),
          ),
          if (d.mine)
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.ios_share),
              onPressed: () => showShareDesignSheet(
                context,
                designId: d.id,
                designName: d.name,
                onChanged: _refresh,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Front')),
              ButtonSegment(value: true, label: Text('Back')),
            ],
            selected: {_back},
            onSelectionChanged: (s) => setState(() => _back = s.first),
          ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AspectRatio(
                aspectRatio: 1,
                child: DesignPreview(
                  base64Png: _back
                      ? (d.backPreviewImage ?? d.previewImage)
                      : d.previewImage,
                  baseColor: d.designJson?['baseColor'] as String?,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'by ${d.creatorName} (@${d.creatorHandle})',
            style: theme.textTheme.titleMedium,
          ),
          if (d.remixedFromName != null)
            Text(
              'Remix of "${d.remixedFromName}"',
              style: theme.textTheme.bodySmall,
            ),
          if (d.lineage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                children: [
                  for (final (i, h) in d.lineage.indexed) ...[
                    if (i > 0) const Icon(Icons.chevron_right, size: 16),
                    Chip(label: Text('@$h')),
                  ],
                  const Icon(Icons.chevron_right, size: 16),
                  Chip(label: Text('@${d.creatorHandle}')),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: Icon(switch (d.visibility) {
                  'public' => Icons.public,
                  'shared' => Icons.group_outlined,
                  _ => Icons.lock_outline,
                }, size: 16),
                label: Text(switch (d.visibility) {
                  'public' => 'Public',
                  'shared' => d.mine ? 'Shared' : 'Shared with you',
                  _ => 'Private',
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (d.published)
                TextButton.icon(
                  onPressed: _like,
                  icon: Icon(d.liked ? Icons.favorite : Icons.favorite_border),
                  label: Text('${d.likeCount}'),
                ),
              const SizedBox(width: 8),
              if (d.published) Text('${d.remixCount} remixes'),
              const Spacer(),
              if (_canUse)
                DropdownButton<String>(
                  value: _size,
                  items: [
                    for (final s in CustomDesign.sizes)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (v) => setState(() => _size = v ?? _size),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_canUse) ...[
            FilledButton.icon(
              onPressed: _buy,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('Add to cart · ${formatPrice(d.price)}'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DesignStudioScreen(
                    initialDesign: d.toStudioDesign(),
                    remixSource: d,
                  ),
                ),
              ),
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Remix this design'),
            ),
          ] else
            const Text(
              'Shared with you to look at and try on. Its owner has not allowed copies or orders.',
            ),
        ],
      ),
    );
  }
}
