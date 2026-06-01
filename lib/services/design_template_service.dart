import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_design.dart';
import '../services/sanity_service.dart';

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

  // Built-in templates are now managed in Sanity CMS (designTemplate document type).
  // This list is kept as a local fallback only — populated from Sanity on first fetch.
  static List<DesignTemplate> _cachedBuiltInTemplates = [];

  Future<List<DesignTemplate>> getAllTemplates() async {
    if (_cachedBuiltInTemplates.isEmpty) {
      _cachedBuiltInTemplates = await SanityService().fetchDesignTemplates();
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
