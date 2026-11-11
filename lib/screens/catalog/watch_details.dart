import 'package:flutter/material.dart';

import '../../models/watch.dart';
import '../../presentation/patterns/responsive_typography_pattern.dart';

/// The watch-only part of a product page: the specification table, how the
/// case will sit on the wrist, what the water rating allows, and what comes
/// in the box.
class WatchDetails extends StatelessWidget {
  const WatchDetails({super.key, required this.watch});
  final WatchSpecs watch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.7);
    final line = scheme.onSurface.withValues(alpha: 0.12);
    final rows = watch.specRows;
    final fit = watch.fitAdvice;
    final water = watch.waterResistanceAdvice;
    final warranty = watch.warrantyLabel;

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: ResponsiveTypography.h4(context)),
    );
    Widget note(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(color: muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rows.isNotEmpty) ...[
          heading('Specifications'),
          for (final (label, value) in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(label, style: TextStyle(color: muted)),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (fit != null)
          note(
            Icons.straighten,
            'Size and fit',
            '$fit To measure, wrap a tape or a strip of paper around your '
                'wrist just above the bone.',
          ),
        if (water != null) note(Icons.water_drop_outlined, 'In water', water),
        if (warranty != null)
          note(
            Icons.verified_outlined,
            '$warranty warranty',
            'Against manufacturing defects. Keep your order confirmation as '
                'proof of purchase.',
          ),
        if (watch.inTheBox.isNotEmpty)
          note(
            Icons.inventory_2_outlined,
            'In the box',
            watch.inTheBox.join(', '),
          ),
      ],
    );
  }
}
