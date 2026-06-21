import 'package:flutter/material.dart';

/// Static constants used across home screen widgets.
class HomeConstants {
  HomeConstants._();

  /// Quick-access category icons for the icon row.
  static const catIcons = [
    {'label': 'Polo',      'icon': Icons.style_rounded,                 'color': Color(0xFFB65D3C)},
    {'label': 'Sale',      'icon': Icons.discount_rounded,              'color': Color(0xFF8A2BE2)},
  ];

  /// Filter tab labels for the feed tab bar.
  static const feedTabs = [
    'Trending', 'New', 'Following', 'Challenges',
    'Tees', 'Typographic', 'Minimal',
  ];
}
