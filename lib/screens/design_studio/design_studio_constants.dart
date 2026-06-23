import 'package:flutter/material.dart';

class DesignStudioConstants {
  // T-Shirt Colors — full palette grouped by hue
  static const List<Color> tShirtColors = [
    // Whites & Neutrals
    Colors.white,
    Color(0xFFFFFFF0), // Ivory
    Color(0xFFFFFDD0), // Cream
    Color(0xFFD3D3D3), // Light Gray
    Colors.grey,
    Color(0xFF404040), // Dark Gray
    Color(0xFF36454F), // Charcoal
    Colors.black,

    // Pinks & Reds
    Color(0xFFFFB6C1), // Light Pink
    Color(0xFFFFC0CB), // Pink
    Color(0xFFFF69B4), // Hot Pink
    Color(0xFFFF1493), // Deep Pink
    Color(0xFFFF007F), // Rose
    Colors.red,
    Color(0xFFDC143C), // Crimson
    Color(0xFF8B0000), // Dark Red
    Color(0xFF800000), // Maroon

    // Oranges & Yellows
    Color(0xFFFFDAB9), // Peach
    Color(0xFFFF6B35), // Coral
    Colors.orange,
    Color(0xFFFFC107), // Amber
    Color(0xFFFFD700), // Gold
    Colors.yellow,
    Color(0xFFFFF9C4), // Light Yellow

    // Greens
    Color(0xFF98FF98), // Mint
    Color(0xFF90EE90), // Light Green
    Color(0xFF32CD32), // Lime Green
    Colors.green,
    Color(0xFF006400), // Dark Green
    Color(0xFF228B22), // Forest Green
    Color(0xFF9DC183), // Sage
    Color(0xFF808000), // Olive
    Color(0xFF008080), // Teal
    Color(0xFF00CED1), // Dark Turquoise
    Color(0xFF40E0D0), // Turquoise

    // Blues
    Color(0xFFADD8E6), // Light Blue
    Color(0xFF87CEEB), // Sky Blue
    Color(0xFF00BFFF), // Deep Sky Blue
    Colors.blue,
    Color(0xFF4169E1), // Royal Blue
    Color(0xFF0000CD), // Medium Blue
    Color(0xFF000080), // Navy
    Colors.indigo,
    Color(0xFF00BCD4), // Cyan

    // Purples & Violets
    Color(0xFFE6E6FA), // Lavender
    Color(0xFFEE82EE), // Violet
    Color(0xFFDA70D6), // Orchid
    Colors.purple,
    Color(0xFF4B0082), // Indigo Dark
    Color(0xFFFF00FF), // Magenta
    Color(0xFFFF80AB), // Pink Accent

    // Browns & Earth Tones
    Color(0xFFD2B48C), // Tan
    Color(0xFFC19A6B), // Camel
    Color(0xFFD2691E), // Chocolate
    Color(0xFF8B4513), // Brown
    Color(0xFFB7410E), // Rust
    Color(0xFF5C4033), // Dark Brown
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

  // ── Print / design area ───────────────────────────────────────────────────
  // Bounds in element coordinate space (offset from the canvas anchor at
  // elementCanvasOffsetX/Y). Matches the AI prompt's x:-130..130, y:-100..200.
  static const double printAreaMinX = -130;
  static const double printAreaMaxX = 130;
  static const double printAreaMinY = -100;
  static const double printAreaMaxY = 200;

  // ── Element transform limits ──────────────────────────────────────────────
  static const double minElementSize = 12;
  static const double maxElementSize = 220;
  static const double defaultImageSize = 150;
  static const double defaultShapeSize = 80;

  // Center-snapping threshold (logical px) while dragging.
  static const double snapThreshold = 7;

  // Shapes available in the Shapes source.
  static const List<String> availableShapes = ['rect', 'circle', 'triangle', 'line'];
}
