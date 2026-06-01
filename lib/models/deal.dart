import 'package:flutter/material.dart';

class Deal {
  final String id;
  final String label;
  final int originalPrice;
  final int salePrice;
  final int discountPercent;
  final String colorHex;

  const Deal({
    required this.id,
    required this.label,
    required this.originalPrice,
    required this.salePrice,
    required this.discountPercent,
    required this.colorHex,
  });

  Color get color {
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  factory Deal.fromMap(Map<String, dynamic> map) => Deal(
    id: map['_id'] as String? ?? '',
    label: map['label'] as String? ?? '',
    originalPrice: (map['originalPrice'] as num?)?.toInt() ?? 0,
    salePrice: (map['salePrice'] as num?)?.toInt() ?? 0,
    discountPercent: (map['discountPercent'] as num?)?.toInt() ?? 0,
    colorHex: map['colorHex'] as String? ?? '#3B82F6',
  );

  static const List<Map<String, Object>> fallbackRaw = [
    {'id': 'deal_1', 'label': 'Graphic Tee',    'originalPrice': 1299, 'salePrice': 649,  'discountPercent': 50, 'colorHex': '#3B82F6'},
    {'id': 'deal_2', 'label': 'Classic Hoodie', 'originalPrice': 2499, 'salePrice': 1499, 'discountPercent': 40, 'colorHex': '#8B5CF6'},
    {'id': 'deal_3', 'label': 'Polo Shirt',     'originalPrice': 999,  'salePrice': 649,  'discountPercent': 35, 'colorHex': '#14B8A6'},
    {'id': 'deal_4', 'label': 'Jogger Pants',   'originalPrice': 1799, 'salePrice': 989,  'discountPercent': 45, 'colorHex': '#F97316'},
    {'id': 'deal_5', 'label': 'Tank Top',       'originalPrice': 799,  'salePrice': 559,  'discountPercent': 30, 'colorHex': '#22C55E'},
    {'id': 'deal_6', 'label': 'Oversized Tee',  'originalPrice': 1599, 'salePrice': 719,  'discountPercent': 55, 'colorHex': '#EF4444'},
  ];

  static List<Deal> get fallbacks => fallbackRaw
      .map((m) => Deal(
            id: m['id'] as String,
            label: m['label'] as String,
            originalPrice: m['originalPrice'] as int,
            salePrice: m['salePrice'] as int,
            discountPercent: m['discountPercent'] as int,
            colorHex: m['colorHex'] as String,
          ))
      .toList();
}
