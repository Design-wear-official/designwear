import 'package:flutter/material.dart';
import 'package:designwear/presentation/styles/styles.dart';

// banners and dealItems are now managed in Sanity CMS.
// See lib/models/banner.dart and lib/models/deal.dart for fallbacks.

class HomeConstants {
  static const navTabs = [
    'All', 'Collections', 'T-Shirts', 'Hoodies', 'Polo Shirts',
    'Design Studio', 'Trending', 'New Arrivals', 'Sale',
  ];

  static const catIcons = [
    {'label': 'Design',   'icon': Icons.style,                'color': AppColors.accentBlue},
    {'label': 'Trending', 'icon': Icons.local_fire_department, 'color': Colors.orange},
    {'label': 'New In',   'icon': Icons.new_releases_outlined, 'color': AppColors.purple},
    {'label': 'Sale',     'icon': Icons.sell_outlined,         'color': Colors.red},
    {'label': 'T-Shirts', 'icon': Icons.checkroom_outlined,    'color': Colors.teal},
    {'label': 'Hoodies',  'icon': Icons.ac_unit,               'color': Colors.indigo},
    {'label': 'Polo',     'icon': Icons.sports_soccer,         'color': Colors.green},
    {'label': 'Premium',  'icon': Icons.diamond_outlined,      'color': AppColors.gold},
  ];
}

