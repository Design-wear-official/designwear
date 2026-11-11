import 'package:flutter/material.dart';

import '../../models/watch.dart';

/// The parts of the shop the home page can show.
enum ShopCategory {
  all('All', 'All Products'),
  clothing('Clothing', 'Clothing'),
  watches('Watches', 'Watches');

  const ShopCategory(this.label, this.title);

  /// On the chip.
  final String label;

  /// Above the grid.
  final String title;
}

/// All / Clothing / Watches, above the product grid.
class HomeCategoryBar extends StatelessWidget {
  const HomeCategoryBar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.hp,
  });
  final ShopCategory selected;
  final ValueChanged<ShopCategory> onSelected;
  final double hp;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: hp, vertical: 4),
    child: Row(
      children: [
        for (final c in ShopCategory.values) ...[
          ChoiceChip(
            label: Text(c.label),
            selected: c == selected,
            onSelected: (_) => onSelected(c),
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

/// One menu per watch facet (strap, dial colour, movement, case size ...),
/// built from the values the loaded watches actually have.
class WatchFilterBar extends StatelessWidget {
  const WatchFilterBar({
    super.key,
    required this.options,
    required this.filter,
    required this.onChanged,
    required this.hp,
  });
  final Map<WatchFacet, List<String>> options;
  final WatchFilter filter;
  final ValueChanged<WatchFilter> onChanged;
  final double hp;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: hp, vertical: 4),
      child: Row(
        children: [
          for (final MapEntry(key: facet, value: values) in options.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                tooltip: 'Filter by ${facet.label.toLowerCase()}',
                onSelected: (v) => onChanged(filter.toggle(facet, v)),
                itemBuilder: (_) => [
                  for (final v in values)
                    CheckedPopupMenuItem(
                      value: v,
                      checked: filter.isSelected(facet, v),
                      child: Text(v),
                    ),
                ],
                child: _FacetChip(
                  label: facet.label,
                  count: filter.selected[facet]?.length ?? 0,
                ),
              ),
            ),
          if (!filter.isEmpty)
            TextButton(
              onPressed: () => onChanged(const WatchFilter()),
              style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
              child: const Text('Clear'),
            ),
        ],
      ),
    );
  }
}

class _FacetChip extends StatelessWidget {
  const _FacetChip({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = count > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: on ? scheme.primary.withValues(alpha: 0.14) : null,
        border: Border.all(
          color: on ? scheme.primary : scheme.onSurface.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            on ? '$label ($count)' : label,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 20, color: scheme.onSurface),
        ],
      ),
    );
  }
}
