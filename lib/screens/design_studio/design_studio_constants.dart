import 'package:flutter/material.dart';

class DesignStudioConstants {
  // T-Shirt Colors
  static const List<Color> tShirtColors = [
    Colors.white,
    Colors.black,
    Colors.grey,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Color(0xFFFFD700), // Gold
    Color(0xFF8B4513), // Brown
    Color(0xFFFF1493), // Deep Pink
    Color(0xFF00CED1), // Dark Turquoise
  ];

  // Available Stickers
  static const List<String> availableStickers = [
    '⭐',
    '🔥',
    '❤️',
    '🎸',
    '👑',
    '😎',
    '💀',
    '🍕',
    '🎉',
    '⚽',
    '🚀',
    '🌈',
    '🎨',
    '🦄',
    '🏆',
    '💎',
    '🌟',
    '💯',
    '✨',
    '🎭',
    '🎯',
    '🎪',
    '🌙',
  ];

  // Tab Types
  static const List<Map<String, dynamic>> toolTabs = [
    {'icon': Icons.palette, 'label': 'Colors'},
    {'icon': Icons.text_fields, 'label': 'Text'},
    {'icon': Icons.emoji_emotions, 'label': 'Stickers'},
    {'icon': Icons.admin_panel_settings, 'label': 'Templates'},
  ];

  // Canvas Dimensions
  static const double canvasWidth = 300;
  static const double textCanvasOffsetX = 100;
  static const double textCanvasOffsetY = 100;
  static const double stickerCanvasOffsetX = 100;
  static const double stickerCanvasOffsetY = 150;
  static const double elementCanvasOffsetX = 150;
  static const double elementCanvasOffsetY = 120;

  // Auto-save interval
  static const int autoSaveIntervalSeconds = 10;

  // Font size limits
  static const double minFontSize = 10;
  static const double maxFontSize = 80;
  static const double defaultFontSize = 24;
  static const double defaultStickerSize = 60;

  // Panel dimensions
  static const double templatesPanelWidth = 300;
  static const double layersPanelWidth = 280;
}
