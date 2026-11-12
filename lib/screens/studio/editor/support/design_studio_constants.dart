import 'package:flutter/material.dart';

class DesignStudioConstants {
  // Stickers/emojis are user-supplied — we don't ship a preset list.
  // See StickersTab, where users type or paste their own emojis.

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

  /// Keeps a whole element (not just its top-left corner) inside the print area: its left/top edge no
  /// further than the minimum, its right/bottom edge no further than the maximum. An element bigger than
  /// the area is pinned to the minimum edge.
  static ({double x, double y}) clampBox(
    double x,
    double y,
    double width,
    double height,
  ) {
    final maxX = printAreaMaxX - width;
    final maxY = printAreaMaxY - height;
    return (
      x: x.clamp(printAreaMinX, maxX < printAreaMinX ? printAreaMinX : maxX),
      y: y.clamp(printAreaMinY, maxY < printAreaMinY ? printAreaMinY : maxY),
    );
  }

  // ── Element transform limits ──────────────────────────────────────────────
  static const double minElementSize = 12;
  static const double maxElementSize = 220;
  static const double defaultImageSize = 150;
  static const double defaultShapeSize = 80;

  // Center-snapping threshold (logical px) while dragging.
  static const double snapThreshold = 7;

  // Shapes available in the Shapes source.
  static const List<String> availableShapes = [
    'rect',
    'circle',
    'triangle',
    'line',
  ];
}
