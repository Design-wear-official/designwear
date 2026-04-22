
import 'package:flutter/material.dart';

/// Demo templates and content for the design studio 
class DesignStudioDemoService {
  static final DesignStudioDemoService _instance = DesignStudioDemoService._internal();
  factory DesignStudioDemoService() => _instance;
  DesignStudioDemoService._internal();



  /// Demo tips for using the design studio
  List<Map<String, String>> get demoTips => [
        {
          'title': 'Pro Tip: Layering',
          'description': 'Use the layers panel to organize and reorder your design elements easily.',
          'icon': '📚',
        },
        {
          'title': 'Color Harmony',
          'description': 'Try complementary colors for text and background to make your design pop!',
          'icon': '🎨',
        },
        {
          'title': 'Text Sizing',
          'description': 'Use larger fonts for main text and smaller ones for subtitles to create hierarchy.',
          'icon': '🔤',
        },
        {
          'title': 'Balance Elements',
          'description': 'Don\'t overcrowd your design. Leave some breathing room between elements.',
          'icon': '⚖️',
        },
        {
          'title': 'Undo & Redo',
          'description': 'Made a mistake? Use the undo/redo buttons to quickly fix your design.',
          'icon': '↩️',
        },
      ];

  /// Demo text suggestions
  List<String> get demoTextSuggestions => [
        'DREAM BIG',
        'Stay Wild',
        'Good Vibes Only',
        'ADVENTURE AWAITS',
        'Be Yourself',
        'Make It Happen',
        'EXPLORE MORE',
        'Create Magic',
        'RISE & SHINE',
        'Chase Dreams',
        'STAY STRONG',
        'Inspire Others',
        'KEEP GOING',
        'Spread Love',
      ];

  /// Demo color palettes
  List<Map<String, dynamic>> get demoColorPalettes => [
        {
          'name': 'Sunset Vibes',
          'colors': [
            const Color(0xFFFF6B35),
            const Color(0xFFF7931E),
            const Color(0xFFFFD23F),
            const Color(0xFFFFE66D),
          ],
        },
        {
          'name': 'Ocean Blue',
          'colors': [
            const Color(0xFF003566),
            const Color(0xFF0077BE),
            const Color(0xFF0096C7),
            const Color(0xFF00B4D8),
          ],
        },
        {
          'name': 'Forest Green',
          'colors': [
            const Color(0xFF2D5016),
            const Color(0xFF68B030),
            const Color(0xFF8FBC8F),
            const Color(0xFF9ACD32),
          ],
        },
        {
          'name': 'Neon Nights',
          'colors': [
            const Color(0xFF08F7FE),
            const Color(0xFF09FBD3),
            const Color(0xFFFE53BB),
            const Color(0xFFF5D300),
          ],
        },
      ];
}