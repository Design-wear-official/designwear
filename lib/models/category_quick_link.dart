import 'package:flutter/material.dart';

class CategoryQuickLink {
  final String id;
  final String label;
  final String iconName;
  final String colorHex;
  final String action;
  final int tabIndex;
  final int order;

  const CategoryQuickLink({
    required this.id,
    required this.label,
    required this.iconName,
    required this.colorHex,
    required this.action,
    required this.tabIndex,
    required this.order,
  });

  IconData get icon => _iconMap[iconName] ?? Icons.category_outlined;

  Color get color {
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  static const Map<String, IconData> _iconMap = {
    'style': Icons.style,
    'local_fire_department': Icons.local_fire_department,
    'new_releases': Icons.new_releases_outlined,
    'sell': Icons.sell_outlined,
    'checkroom': Icons.checkroom_outlined,
    'ac_unit': Icons.ac_unit,
    'sports_soccer': Icons.sports_soccer,
    'diamond': Icons.diamond_outlined,
    'dry_cleaning': Icons.dry_cleaning_outlined,
    'star': Icons.star_outline_rounded,
    'flash_on': Icons.flash_on_outlined,
    'collections': Icons.collections_outlined,
  };

  factory CategoryQuickLink.fromMap(Map<String, dynamic> map) =>
      CategoryQuickLink(
        id: map['_id'] as String? ?? '',
        label: map['label'] as String? ?? '',
        iconName: map['iconName'] as String? ?? 'category',
        colorHex: map['colorHex'] as String? ?? '#3B82F6',
        action: map['action'] as String? ?? 'tab',
        tabIndex: (map['tabIndex'] as num?)?.toInt() ?? 0,
        order: (map['order'] as num?)?.toInt() ?? 0,
      );
}
