import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:designwear/models/models.dart';

class SavedDesign {
  final String id;
  final String name;
  final CustomDesign design;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;

  SavedDesign({
    required this.id,
    required this.name,
    required this.design,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
  });

  SavedDesign copyWith({
    String? id,
    String? name,
    CustomDesign? design,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailPath,
  }) {
    return SavedDesign(
      id: id ?? this.id,
      name: name ?? this.name,
      design: design ?? this.design,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'design': design.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'thumbnailPath': thumbnailPath,
    };
  }

  factory SavedDesign.fromJson(Map<String, dynamic> json) {
    return SavedDesign(
      id: json['id'],
      name: json['name'],
      design: CustomDesign.fromJson(json['design']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      thumbnailPath: json['thumbnailPath'],
    );
  }
}

class DesignStorageService {
  static const String _savedDesignsKey = 'saved_designs';
  static const String _autoSaveKey = 'auto_save_design';

  Future<List<SavedDesign>> getSavedDesigns() async {
    final prefs = await SharedPreferences.getInstance();
    final designsJson = prefs.getStringList(_savedDesignsKey) ?? [];

    return designsJson.map((jsonStr) {
      final json = jsonDecode(jsonStr);
      return SavedDesign.fromJson(json);
    }).toList();
  }

  Future<void> saveDesign(SavedDesign savedDesign) async {
    final prefs = await SharedPreferences.getInstance();
    final savedDesigns = await getSavedDesigns();

    // Remove existing design with same id (if any)
    savedDesigns.removeWhere((d) => d.id == savedDesign.id);

    // Add new/updated design
    savedDesigns.add(savedDesign);

    // Sort by updated date (most recent first)
    savedDesigns.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Save to preferences
    final designsJson = savedDesigns
        .map((d) => jsonEncode(d.toJson()))
        .toList();
    await prefs.setStringList(_savedDesignsKey, designsJson);
  }

  Future<void> deleteDesign(String designId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedDesigns = await getSavedDesigns();

    savedDesigns.removeWhere((d) => d.id == designId);

    final designsJson = savedDesigns
        .map((d) => jsonEncode(d.toJson()))
        .toList();
    await prefs.setStringList(_savedDesignsKey, designsJson);
  }

  Future<SavedDesign?> getDesignById(String designId) async {
    final savedDesigns = await getSavedDesigns();
    try {
      return savedDesigns.firstWhere((d) => d.id == designId);
    } catch (e) {
      return null;
    }
  }

  Future<void> autoSaveDesign(CustomDesign design) async {
    final prefs = await SharedPreferences.getInstance();
    final designJson = jsonEncode(design.toJson());
    await prefs.setString(_autoSaveKey, designJson);
  }

  Future<CustomDesign?> getAutoSavedDesign() async {
    final prefs = await SharedPreferences.getInstance();
    final designJson = prefs.getString(_autoSaveKey);

    if (designJson != null) {
      try {
        final json = jsonDecode(designJson);
        return CustomDesign.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearAutoSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_autoSaveKey);
  }

  String generateDesignId() {
    return 'design_${DateTime.now().millisecondsSinceEpoch}';
  }

  String generateDefaultName() {
    final now = DateTime.now();
    return 'Design ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }
}
