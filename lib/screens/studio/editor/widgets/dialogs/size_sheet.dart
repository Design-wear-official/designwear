import 'package:designwear/models/models.dart';
import 'package:designwear/screens/studio/editor/canvas/garment_registry.dart';
import 'package:flutter/material.dart';

/// The size picker: the garment's size chart (flat chest, length and sleeve in cm) with a tap-to-choose row
/// per size. Without a chart from the business, the standard sizes are offered without measurements.
Future<void> showSizeSheet(
  BuildContext context, {
  required Garment garment,
  required String? selected,
  required ValueChanged<String> onSelected,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (ctx) => SizeSheet(
    garment: garment,
    selected: selected,
    onSelected: (s) {
      onSelected(s);
      Navigator.of(ctx).pop();
    },
  ),
);

class SizeSheet extends StatelessWidget {
  const SizeSheet({
    super.key,
    required this.garment,
    required this.selected,
    required this.onSelected,
  });

  final Garment garment;
  final String? selected;
  final ValueChanged<String> onSelected;

  static String _cm(double? v) => v == null
      ? '–'
      : (v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final chart = {for (final s in garment.sizes) s.size: s};
    final order = CustomDesign.sizes;
    final rows = [
      ...order.where(chart.containsKey),
      ...chart.keys.where((k) => !order.contains(k)),
    ];
    final sizes = rows.isEmpty ? order : rows;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size', style: t.titleLarge),
            const SizedBox(height: 4),
            Text(
              chart.isEmpty
                  ? 'Pick the size you want.'
                  : 'Flat measurements in cm.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 12),
            if (chart.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 72),
                    for (final h in ['Chest', 'Length', 'Sleeve'])
                      Expanded(child: Text(h, style: t.labelSmall)),
                  ],
                ),
              ),
            for (final s in sizes)
              InkWell(
                key: ValueKey('size-$s'),
                onTap: () => onSelected(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Row(
                          children: [
                            Icon(
                              s == selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s,
                              style: t.titleSmall?.copyWith(
                                fontWeight: s == selected
                                    ? FontWeight.w800
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (chart[s] != null) ...[
                        Expanded(child: Text(_cm(chart[s]!.chestCm))),
                        Expanded(child: Text(_cm(chart[s]!.lengthCm))),
                        Expanded(child: Text(_cm(chart[s]!.sleeveCm))),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
