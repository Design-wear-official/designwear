import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:designwear/models/models.dart';

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

  // Built-in templates ship with the app (the starter designs below); the
  // person's own saved templates are added after them.
  static List<DesignTemplate> _cachedBuiltInTemplates = [];

  List<DesignTemplate> _builtIn() => [
    for (final d in getStarterDesigns())
      DesignTemplate(
        id: 'builtin_${d.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
        name: d.name,
        description: 'Starter design',
        category: 'graphic',
        design: d,
        thumbnailUrl: '',
        tags: const ['starter'],
      ),
  ];

  Future<List<DesignTemplate>> getAllTemplates() async {
    if (_cachedBuiltInTemplates.isEmpty) {
      _cachedBuiltInTemplates = _builtIn();
    }
    final customTemplates = await getCustomTemplates();
    return [..._cachedBuiltInTemplates, ...customTemplates];
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
      return _cachedBuiltInTemplates.firstWhere((t) => t.id == id);
    } catch (_) {
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

  /// Built-in auto-start designs shown when the studio opens on a blank canvas.
  List<CustomDesign> getStarterDesigns() {
    return [
      CustomDesign(
        baseColor: '0xFFE65100',
        name: 'Sunset Vibes',
        productType: 'T-Shirt',
        elements: [
          DesignElement(
            id: 'sv_t',
            type: DesignElementType.text,
            content: 'SUNSET VIBES',
            x: -60,
            y: -30,
            size: 30,
            color: '0xFFFFFFFF',
            properties: {'fontFamily': 'Oswald', 'bold': true, 'shadow': true},
          ),
          DesignElement(
            id: 'sv_s',
            type: DesignElementType.sticker,
            content: '🌅',
            x: -15,
            y: 40,
            size: 60,
            color: '0xFFFFFFFF',
            properties: {},
          ),
        ],
      ),
      CustomDesign(
        baseColor: '0xFF111111',
        name: 'Midnight',
        productType: 'T-Shirt',
        elements: [
          DesignElement(
            id: 'mn_t',
            type: DesignElementType.text,
            content: 'MIDNIGHT',
            x: -55,
            y: -20,
            size: 36,
            color: '0xFFFFFFFF',
            properties: {'fontFamily': 'Oswald', 'bold': true},
          ),
          DesignElement(
            id: 'mn_s',
            type: DesignElementType.sticker,
            content: '🌙',
            x: -15,
            y: 45,
            size: 55,
            color: '0xFFFFFFFF',
            properties: {},
          ),
        ],
      ),
      CustomDesign(
        baseColor: '0xFF1B5E20',
        name: 'Wild & Free',
        productType: 'T-Shirt',
        elements: [
          DesignElement(
            id: 'wf_t',
            type: DesignElementType.text,
            content: 'WILD & FREE',
            x: -60,
            y: -25,
            size: 26,
            color: '0xFFFFFFFF',
            properties: {'fontFamily': 'Pacifico', 'shadow': true},
          ),
          DesignElement(
            id: 'wf_s',
            type: DesignElementType.sticker,
            content: '🌿',
            x: -15,
            y: 45,
            size: 58,
            color: '0xFFFFFFFF',
            properties: {},
          ),
        ],
      ),
      CustomDesign(
        baseColor: '0xFF880E4F',
        name: 'Hustle',
        productType: 'T-Shirt',
        elements: [
          DesignElement(
            id: 'hu_t1',
            type: DesignElementType.text,
            content: 'HUSTLE',
            x: -45,
            y: -35,
            size: 42,
            color: '0xFFFFFFFF',
            properties: {'fontFamily': 'Oswald', 'bold': true},
          ),
          DesignElement(
            id: 'hu_t2',
            type: DesignElementType.text,
            content: 'HARDER',
            x: -38,
            y: 20,
            size: 32,
            color: '0xFFFF80AB',
            properties: {'fontFamily': 'Oswald', 'bold': true},
          ),
          DesignElement(
            id: 'hu_s',
            type: DesignElementType.sticker,
            content: '🔥',
            x: -15,
            y: 70,
            size: 50,
            color: '0xFFFFFFFF',
            properties: {},
          ),
        ],
      ),
      CustomDesign(
        baseColor: '0xFF006064',
        name: 'Zen Mode',
        productType: 'T-Shirt',
        elements: [
          DesignElement(
            id: 'zm_t',
            type: DesignElementType.text,
            content: 'ZEN MODE',
            x: -50,
            y: -20,
            size: 32,
            color: '0xFFE0F7FA',
            properties: {'fontFamily': 'Comfortaa', 'italic': true},
          ),
          DesignElement(
            id: 'zm_s',
            type: DesignElementType.sticker,
            content: '☮️',
            x: -15,
            y: 40,
            size: 60,
            color: '0xFFFFFFFF',
            properties: {},
          ),
        ],
      ),
      CustomDesign(
        baseColor: '0xFF1A237E',
        name: 'Galaxy',
        productType: 'T-Shirt',
        elements: [
          DesignElement(
            id: 'gx_t',
            type: DesignElementType.text,
            content: 'GALAXY',
            x: -45,
            y: -25,
            size: 40,
            color: '0xFFE8EAF6',
            properties: {'fontFamily': 'Oswald', 'bold': true, 'shadow': true},
          ),
          DesignElement(
            id: 'gx_s',
            type: DesignElementType.sticker,
            content: '✨',
            x: -15,
            y: 42,
            size: 58,
            color: '0xFFFFFFFF',
            properties: {},
          ),
        ],
      ),
      CustomDesign(
        baseColor: '0xFFF06292',
        name: 'Summer Days',
        productType: 'T-Shirt',
        elements: [
          DesignElement(
            id: 'sd_t',
            type: DesignElementType.text,
            content: 'SUMMER DAYS',
            x: -65,
            y: -25,
            size: 24,
            color: '0xFFFFFFFF',
            properties: {'fontFamily': 'Pacifico', 'shadow': true},
          ),
          DesignElement(
            id: 'sd_s',
            type: DesignElementType.sticker,
            content: '🌊',
            x: -15,
            y: 42,
            size: 58,
            color: '0xFFFFFFFF',
            properties: {},
          ),
        ],
      ),
      CustomDesign(
        baseColor: '0xFF0D47A1',
        name: 'Champion',
        productType: 'T-Shirt',
        elements: [
          DesignElement(
            id: 'ch_t',
            type: DesignElementType.text,
            content: 'CHAMPION',
            x: -55,
            y: -20,
            size: 34,
            color: '0xFFFFD700',
            properties: {'fontFamily': 'Oswald', 'bold': true, 'shadow': true},
          ),
          DesignElement(
            id: 'ch_s',
            type: DesignElementType.sticker,
            content: '🏆',
            x: -15,
            y: 42,
            size: 60,
            color: '0xFFFFFFFF',
            properties: {},
          ),
        ],
      ),
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
      'Roboto',
      'Open Sans',
      'Lato',
      'Montserrat',
      'Playfair Display',
      'Merriweather',
      'Nunito',
      'Poppins',
      'Raleway',
      'Ubuntu',
    ];
  }
}
