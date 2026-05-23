import 'package:flutter/material.dart';
import '../../presentation/styles/app_colors.dart';

class HomeConstants {
  static const banners = [
    {
      'badge': 'NEW COLLECTION',
      'title': 'Signature Style,\nPremium Comfort',
      'sub': 'Explore handcrafted apparel for the modern wardrobe.',
      'cta': 'SHOP NOW',
      'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=2070&auto=format&fit=crop',
      'ctaColor': 'purple',
    },
    {
      'badge': 'DESIGN STUDIO',
      'title': 'Design Your\nOwn Style',
      'sub': 'Create unique custom apparel that speaks for you.',
      'cta': 'START CREATING',
      'image': 'https://images.unsplash.com/photo-1503342394128-c104d54dba01?q=80&w=2069&auto=format&fit=crop',
      'ctaColor': 'blue',
    },
    {
      'badge': '🔥 FLASH SALE',
      'title': 'Up to 50% Off\nToday Only',
      'sub': 'Limited-time deals on premium collections.',
      'cta': 'GRAB DEAL',
      'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?q=80&w=2069&auto=format&fit=crop',
      'ctaColor': 'orange',
    },
  ];

  static const navTabs = [
    'All', 'Collections', 'T-Shirts', 'Hoodies', 'Polo Shirts',
    'Design Studio', 'Trending', 'New Arrivals', 'Sale',
  ];

  static const catIcons = [
    {'label': 'Design',   'icon': Icons.style,                 'color': AppColors.accentBlue},
    {'label': 'Trending', 'icon': Icons.local_fire_department,  'color': Colors.orange},
    {'label': 'New In',   'icon': Icons.new_releases_outlined,  'color': AppColors.purple},
    {'label': 'Sale',     'icon': Icons.sell_outlined,          'color': Colors.red},
    {'label': 'T-Shirts', 'icon': Icons.checkroom_outlined,     'color': Colors.teal},
    {'label': 'Hoodies',  'icon': Icons.ac_unit,                'color': Colors.indigo},
    {'label': 'Polo',     'icon': Icons.sports_soccer,          'color': Colors.green},
    {'label': 'Premium',  'icon': Icons.diamond_outlined,       'color': AppColors.gold},
  ];

  static const dealItems = [
    {'label': 'Graphic Tee',    'original': 1299, 'sale': 649,  'off': 50, 'color': AppColors.accentBlue},
    {'label': 'Classic Hoodie', 'original': 2499, 'sale': 1499, 'off': 40, 'color': AppColors.purple},
    {'label': 'Polo Shirt',     'original': 999,  'sale': 649,  'off': 35, 'color': Colors.teal},
    {'label': 'Jogger Pants',   'original': 1799, 'sale': 989,  'off': 45, 'color': Colors.orange},
    {'label': 'Tank Top',       'original': 799,  'sale': 559,  'off': 30, 'color': Colors.green},
    {'label': 'Oversized Tee',  'original': 1599, 'sale': 719,  'off': 55, 'color': Colors.red},
  ];
}

