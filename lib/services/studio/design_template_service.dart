import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:designwear/models/models.dart';

import '../../api/api_client.dart';
import '../../logging/app_log.dart';

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
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'graphic',
      design: CustomDesign.fromJson(
        (json['design'] as Map).cast<String, dynamic>(),
      ),
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class DesignTemplateService {
  static const String _customTemplatesKey = 'custom_design_templates';

  // The starter designs are the business's list in SethuCMS, served by the API at `GET /v1/templates`.
  // The app ships none of its own; the person's own saved templates are added after them.
  static List<DesignTemplate> _starters = [];

  /// Bumps whenever the starter list changes.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  /// Fetches the starter designs. Silent on any failure: the list stays as it was.
  static Future<void> loadTemplates([ApiClient? api]) async {
    if (api == null) return;
    try {
      final j = await api.get('/v1/templates');
      final list = <DesignTemplate>[];
      for (final e in (j['data'] as List? ?? const [])) {
        if (e is! Map) continue;
        try {
          list.add(DesignTemplate.fromJson(e.cast<String, dynamic>()));
        } catch (_) {
          // A malformed row is skipped; the rest still count.
        }
      }
      _starters = list;
      revision.value++;
    } catch (e) {
      AppLog.instance.info('studio', 'Starter designs unavailable: $e');
    }
  }

  /// Back to no starter designs (tests).
  @visibleForTesting
  static void reset() {
    _starters = [];
    revision.value++;
  }

  Future<List<DesignTemplate>> getAllTemplates() async {
    final customTemplates = await getCustomTemplates();
    return [..._starters, ...customTemplates];
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
      return _starters.firstWhere((t) => t.id == id);
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

  /// The starter designs offered when the studio opens on a blank canvas (empty until the list arrives).
  List<CustomDesign> getStarterDesigns() => [
    for (final t in _starters) t.design,
  ];

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
