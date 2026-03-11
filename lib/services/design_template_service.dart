import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_design.dart';

class DesignTemplate {
  final String id;
  final String name;
  final String description;
  final String category; // 'vintage', 'modern', 'minimalist', 'graphic', etc.
  final CustomDesign design;
  final String thumbnailUrl;
  final List<String> tags;

  DesignTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.design,
    required this.thumbnailUrl,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'design': design.toJson(),
      'thumbnailUrl': thumbnailUrl,
      'tags': tags,
    };
  }

  factory DesignTemplate.fromJson(Map<String, dynamic> json) {
    return DesignTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      design: CustomDesign.fromJson(json['design']),
      thumbnailUrl: json['thumbnailUrl'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class DesignTemplateService {
  static const String _customTemplatesKey = 'custom_design_templates';

  // Pre-built templates
  static final List<DesignTemplate> _builtInTemplates = [
    DesignTemplate(
      id: 'vintage_rock',
      name: 'Vintage Rock',
      description: 'Classic rock band style with distressed text',
      category: 'vintage',
      thumbnailUrl: 'assets/images/templates/vintage_rock.png',
      tags: ['music', 'vintage', 'rock'],
      design: CustomDesign(
        baseColor: '0xFF2C2C2C',
        elements: [
          DesignElement(
            id: 'vintage_text',
            type: 'text',
            content: 'ROCK BAND',
            x: 0,
            y: -20,
            size: 32,
            color: '0xFFFFFFFF',
            properties: {
              'fontFamily': 'RockSalt',
              'bold': true,
              'shadow': true,
              'shadowColor': '0xFF000000',
              'shadowOffset': {'x': 2.0, 'y': 2.0},
            },
          ),
          DesignElement(
            id: 'vintage_sticker',
            type: 'sticker',
            content: '🎸',
            x: 0,
            y: 40,
            size: 60,
            color: '0xFFFFD700',
            properties: {},
          ),
        ],
      ),
    ),
    DesignTemplate(
      id: 'minimalist_quote',
      name: 'Minimalist Quote',
      description: 'Clean and simple motivational text',
      category: 'minimalist',
      thumbnailUrl: 'assets/images/templates/minimalist.png',
      tags: ['quote', 'minimal', 'clean'],
      design: CustomDesign(
        baseColor: '0xFFFFFFFF',
        elements: [
          DesignElement(
            id: 'main_text',
            type: 'text',
            content: 'BE YOURSELF',
            x: 0,
            y: -10,
            size: 24,
            color: '0xFF2C2C2C',
            properties: {
              'fontFamily': 'Outfit',
              'bold': false,
              'italic': false,
              'letterSpacing': 2.0,
            },
          ),
          DesignElement(
            id: 'sub_text',
            type: 'text',
            content: 'everyone else is taken',
            x: 0,
            y: 20,
            size: 14,
            color: '0xFF666666',
            properties: {'fontFamily': 'Outfit', 'bold': false, 'italic': true},
          ),
        ],
      ),
    ),
    DesignTemplate(
      id: 'sports_team',
      name: 'Sports Team',
      description: 'Athletic team style with number and team name',
      category: 'sports',
      thumbnailUrl: 'assets/images/templates/sports.png',
      tags: ['sports', 'team', 'athletic'],
      design: CustomDesign(
        baseColor: '0xFF1E3A8A',
        elements: [
          DesignElement(
            id: 'team_name',
            type: 'text',
            content: 'CHAMPIONS',
            x: 0,
            y: -30,
            size: 28,
            color: '0xFFFFFFFF',
            properties: {
              'fontFamily': 'Oswald',
              'bold': true,
              'letterSpacing': 3.0,
            },
          ),
          DesignElement(
            id: 'number',
            type: 'text',
            content: '23',
            x: 0,
            y: 10,
            size: 72,
            color: '0xFFFFD700',
            properties: {
              'fontFamily': 'Oswald',
              'bold': true,
              'shadow': true,
              'shadowColor': '0xFF000000',
            },
          ),
          DesignElement(
            id: 'sport_icon',
            type: 'sticker',
            content: '⚽',
            x: 0,
            y: 80,
            size: 40,
            color: '0xFFFFFFFF',
            properties: {},
          ),
        ],
      ),
    ),
    DesignTemplate(
      id: 'urban_street',
      name: 'Urban Street',
      description: 'Street art inspired graffiti style',
      category: 'urban',
      thumbnailUrl: 'assets/images/templates/urban.png',
      tags: ['street', 'urban', 'graffiti'],
      design: CustomDesign(
        baseColor: '0xFF000000',
        elements: [
          DesignElement(
            id: 'street_text',
            type: 'text',
            content: 'STREET ART',
            x: 0,
            y: 0,
            size: 36,
            color: '0xFFFF6B35',
            properties: {
              'fontFamily': 'BungeeShade',
              'bold': true,
              'shadow': true,
              'shadowColor': '0xFFFFD23F',
              'shadowOffset': {'x': 3.0, 'y': 3.0},
            },
          ),
          DesignElement(
            id: 'spray_can',
            type: 'sticker',
            content: '🎨',
            x: 60,
            y: -10,
            size: 30,
            color: '0xFFFFFFFF',
            properties: {},
          ),
        ],
      ),
    ),
    DesignTemplate(
      id: 'nature_lover',
      name: 'Nature Lover',
      description: 'Earth-friendly design with natural elements',
      category: 'nature',
      thumbnailUrl: 'assets/images/templates/nature.png',
      tags: ['nature', 'eco', 'earth'],
      design: CustomDesign(
        baseColor: '0xFF22C55E',
        elements: [
          DesignElement(
            id: 'nature_text',
            type: 'text',
            content: 'EARTH LOVER',
            x: 0,
            y: -20,
            size: 26,
            color: '0xFFFFFFFF',
            properties: {
              'fontFamily': 'Pacifico',
              'bold': false,
              'italic': false,
            },
          ),
          DesignElement(
            id: 'tree_icon',
            type: 'sticker',
            content: '🌱',
            x: -40,
            y: 20,
            size: 50,
            color: '0xFF16A34A',
            properties: {},
          ),
          DesignElement(
            id: 'earth_icon',
            type: 'sticker',
            content: '🌍',
            x: 40,
            y: 20,
            size: 50,
            color: '0xFF3B82F6',
            properties: {},
          ),
        ],
      ),
    ),
  ];

  Future<List<DesignTemplate>> getAllTemplates() async {
    final customTemplates = await getCustomTemplates();
    return [..._builtInTemplates, ...customTemplates];
  }

  Future<List<DesignTemplate>> getTemplatesByCategory(String category) async {
    final allTemplates = await getAllTemplates();
    return allTemplates
        .where((template) => template.category == category)
        .toList();
  }

  Future<List<DesignTemplate>> searchTemplates(String query) async {
    final allTemplates = await getAllTemplates();
    final lowercaseQuery = query.toLowerCase();

    return allTemplates.where((template) {
      return template.name.toLowerCase().contains(lowercaseQuery) ||
          template.description.toLowerCase().contains(lowercaseQuery) ||
          template.tags.any(
            (tag) => tag.toLowerCase().contains(lowercaseQuery),
          );
    }).toList();
  }

  DesignTemplate? getTemplateById(String id) {
    try {
      return _builtInTemplates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<DesignTemplate>> getCustomTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final templatesJson = prefs.getStringList(_customTemplatesKey) ?? [];

    return templatesJson.map((jsonStr) {
      final json = jsonDecode(jsonStr);
      return DesignTemplate.fromJson(json);
    }).toList();
  }

  Future<void> saveCustomTemplate(DesignTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    final customTemplates = await getCustomTemplates();

    // Remove existing template with same id (if any)
    customTemplates.removeWhere((t) => t.id == template.id);

    // Add new template
    customTemplates.add(template);

    // Save to preferences
    final templatesJson = customTemplates
        .map((t) => jsonEncode(t.toJson()))
        .toList();
    await prefs.setStringList(_customTemplatesKey, templatesJson);
  }

  Future<void> deleteCustomTemplate(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    final customTemplates = await getCustomTemplates();

    customTemplates.removeWhere((t) => t.id == templateId);

    final templatesJson = customTemplates
        .map((t) => jsonEncode(t.toJson()))
        .toList();
    await prefs.setStringList(_customTemplatesKey, templatesJson);
  }

  List<String> getAvailableCategories() {
    return [
      'vintage',
      'minimalist',
      'sports',
      'urban',
      'nature',
      'corporate',
      'artistic',
      'funny',
    ];
  }

  List<String> getAvailableFonts() {
    return [
      'Outfit',
      'RockSalt',
      'Oswald',
      'Pacifico',
      'BungeeShade',
      'Fredoka',
      'Comfortaa',
      'Righteous',
    ];
  }
}
