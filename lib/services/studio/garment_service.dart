import '../../api/api_client.dart';
import '../../logging/app_log.dart';
import '../../screens/studio/editor/canvas/garment_registry.dart';

/// Garment templates the studio can render. The app ships a few ([GarmentRegistry]); the business
/// edits the real list in SethuCMS and the API serves it at `GET /v1/garments`.
class GarmentService {
  /// Fetches the list and hands it to the registry. Silent on any failure: the bundled garments stay.
  static Future<void> loadGarments([ApiClient? api]) async {
    if (api == null) return;
    try {
      final j = await api.get('/v1/garments');
      final list = <Garment>[];
      for (final e in (j['data'] as List? ?? const [])) {
        if (e is! Map) continue;
        try {
          list.add(Garment.fromJson(e.cast<String, dynamic>()));
        } catch (_) {
          // A malformed row is skipped; the rest still count.
        }
      }
      if (list.isNotEmpty) GarmentRegistry.updateFromBackend(list);
    } catch (e) {
      AppLog.instance.info('studio', 'Garment list unavailable: $e');
    }
  }

  static void invalidate() {}
}
