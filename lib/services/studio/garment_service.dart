import '../../screens/studio/editor/canvas/garment_registry.dart';

/// Garment templates the studio can render. They ship with the app (see
/// [GarmentRegistry]); a CMS-driven list can replace them later via
/// [GarmentRegistry.updateFromBackend].
class GarmentService {
  static Future<void> loadGarments() async {}
  static void invalidate() {}
}
