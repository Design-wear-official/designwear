import 'package:designwear/screens/studio/editor/canvas/garment_registry.dart';
import 'package:designwear/services/ai/layers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the layers and contact sheet of the artwork the assistant made: the four mock-up views, the flat
/// transparent layer of each print area (with its print size), and links to the sheet (PNG and PDF), each
/// print-size file and the 3-D model.
Future<void> showLayersSheet(
  BuildContext context, {
  required LayerJob job,
  required Garment garment,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => LayersSheet(job: job, garment: garment),
);

class LayersSheet extends StatelessWidget {
  const LayersSheet({
    super.key,
    required this.job,
    required this.garment,
    this.open,
  });

  final LayerJob job;
  final Garment garment;

  /// How a link is opened (a browser by default); replaced in tests.
  final Future<bool> Function(Uri url)? open;

  static const _views = [
    ('front', 'Front'),
    ('right', 'Right side'),
    ('back', 'Back'),
    ('left', 'Left side'),
  ];

  /// The print area for [layer]: the garment's own list first, then what the job says.
  PrintPlacement? placementFor(PrintLayer layer) {
    final own = garment.placements.where((p) => p.key == layer.key).firstOrNull;
    if (own != null) return own;
    if (layer.width == null || layer.height == null) return null;
    return PrintPlacement(
      key: layer.key,
      label: layer.label,
      width: layer.width!,
      height: layer.height!,
      dpi: layer.dpi ?? 300,
      provisional: layer.provisional,
    );
  }

  Future<void> _go(BuildContext context, String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    var ok = false;
    if (uri != null) {
      try {
        ok =
            await (open ??
                (u) => launchUrl(u, mode: LaunchMode.externalApplication))(uri);
      } catch (_) {}
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't open that file.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final provisional = job.layers.any(
      (l) => l.provisional || (placementFor(l)?.provisional ?? false),
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Layers & sheet', style: t.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${garment.label}${job.name.isEmpty ? '' : ' · ${job.name}'}',
                style: t.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('Mock-up views', style: t.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (key, label) in _views)
                    if (job.views[key] != null)
                      _Tile(
                        label: label,
                        child: Image.network(
                          job.views[key]!,
                          key: ValueKey('view-$key'),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const _Missing(),
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Print layers', style: t.titleSmall),
              const SizedBox(height: 8),
              for (final l in job.layers) _layerCard(context, l),
              if (provisional)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'Sizes marked "provisional" are estimates until the print partner confirms them.',
                    key: const ValueKey('provisional-note'),
                    style: t.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (job.sheetUrl != null)
                    FilledButton.tonalIcon(
                      key: const ValueKey('sheet-png'),
                      onPressed: () => _go(context, job.sheetUrl),
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Sheet (PNG)'),
                    ),
                  if (job.sheetPdfUrl != null)
                    FilledButton.tonalIcon(
                      key: const ValueKey('sheet-pdf'),
                      onPressed: () => _go(context, job.sheetPdfUrl),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Sheet (PDF)'),
                    ),
                  // No 3-D viewer package is bundled, so the model is a link.
                  if (job.modelUrl != null)
                    OutlinedButton.icon(
                      key: const ValueKey('model-link'),
                      onPressed: () => _go(context, job.modelUrl),
                      icon: const Icon(Icons.view_in_ar_outlined),
                      label: const Text('3-D model (GLB)'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _layerCard(BuildContext context, PrintLayer l) {
    final t = Theme.of(context).textTheme;
    final p = placementFor(l);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: Checkerboard()),
                if (l.ok && l.url != null)
                  Image.network(
                    l.url!,
                    key: ValueKey('layer-${l.key}'),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const _Missing(),
                  )
                else
                  const _Missing(),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p?.label ?? l.label, style: t.titleSmall),
                if (p != null)
                  Text(
                    p.sizeText,
                    key: ValueKey('size-${l.key}'),
                    style: t.bodySmall,
                  ),
                if (p?.provisional ?? l.provisional)
                  Text('Provisional size', style: t.bodySmall),
                if (!l.ok)
                  Text("Couldn't be drawn this time.", style: t.bodySmall),
                for (final w in l.warnings)
                  Text(_warning(w), style: t.bodySmall),
                if (l.printUrl != null)
                  TextButton.icon(
                    key: ValueKey('print-${l.key}'),
                    onPressed: () => _go(context, l.printUrl),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Print-size file'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _warning(String w) => switch (w) {
    'no_background_found' => 'The background could not be removed cleanly.',
    _ => w.replaceAll('_', ' '),
  };
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 120,
    child: Column(
      children: [
        AspectRatio(aspectRatio: 0.8, child: child),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _Missing extends StatelessWidget {
  const _Missing();
  @override
  Widget build(BuildContext context) => Center(
    child: Icon(
      Icons.image_not_supported_outlined,
      color: Theme.of(context).colorScheme.outline,
    ),
  );
}

/// The grey-and-white squares that show a picture is transparent.
class Checkerboard extends CustomPainter {
  const Checkerboard();
  @override
  void paint(Canvas canvas, Size size) {
    const s = 8.0;
    final a = Paint()..color = const Color(0xFFFFFFFF);
    final b = Paint()..color = const Color(0xFFD9D9D9);
    for (var y = 0; y * s < size.height; y++) {
      for (var x = 0; x * s < size.width; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * s, y * s, s, s),
          (x + y).isEven ? a : b,
        );
      }
    }
  }

  @override
  bool shouldRepaint(Checkerboard old) => false;
}
