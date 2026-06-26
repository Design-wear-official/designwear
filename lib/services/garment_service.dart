import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:designwear/config/config.dart';
import 'package:designwear/screens/design_studio/garment_registry.dart';

/// Fetches garment template data (front/back image URLs) from the backend and
/// updates [GarmentRegistry] so the design canvas uses CMS-hosted images.
class GarmentService {
  static bool _loaded = false;

  /// Call once at app startup (or when entering the design studio).
  /// Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> loadGarments() async {
    if (_loaded) return;
    try {
      final baseUrl = WebApiConfig.baseUrl;
      final uri = Uri.parse('$baseUrl/garments');
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final list = (body['data'] as List<dynamic>)
              .map((e) => Garment.fromJson(e as Map<String, dynamic>))
              .toList();
          GarmentRegistry.updateFromBackend(list);
          _loaded = true;
        }
      }
    } catch (e) {
      // Non-fatal: the registry keeps its bundled defaults.
      debugPrint('GarmentService: failed to load from backend — $e');
    }
  }

  /// Force a refresh on the next call to [loadGarments].
  static void invalidate() => _loaded = false;
}
