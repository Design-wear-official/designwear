import 'package:designwear/models/models.dart';

/// Descriptor for a garment the studio can render.
///
/// Images are resolved in priority order:
///   1. Network URL from the backend (`frontUrl` / `backUrl`)
///   2. Bundled asset path (`frontAsset` / `backAsset`)
///   3. `null` → canvas shows the "coming soon" placeholder
class Garment {
  final String id;
  final String label;
  final String? frontAsset;
  final String? backAsset;
  // Network URLs fetched from the backend CMS; override bundled assets when set.
  final String? frontUrl;
  final String? backUrl;
  final bool supportsCollarPocketOverlay;

  const Garment({
    required this.id,
    required this.label,
    this.frontAsset,
    this.backAsset,
    this.frontUrl,
    this.backUrl,
    this.supportsCollarPocketOverlay = false,
  });

  /// Returns the network URL for [side] if available, otherwise the local asset path.
  String? imageUrl(DesignSide side) {
    if (side == DesignSide.back) return backUrl ?? backAsset;
    return frontUrl ?? frontAsset;
  }

  /// Whether to load [side] from the network (vs. a bundled asset).
  bool isNetworkImage(DesignSide side) {
    if (side == DesignSide.back) return backUrl != null;
    return frontUrl != null;
  }

  /// Backwards-compat helper — true when any image source is available.
  bool hasAsset(DesignSide side) => imageUrl(side) != null;

  Garment withUrls({String? frontUrl, String? backUrl}) => Garment(
        id: id,
        label: label,
        frontAsset: frontAsset,
        backAsset: backAsset,
        frontUrl: frontUrl ?? this.frontUrl,
        backUrl: backUrl ?? this.backUrl,
        supportsCollarPocketOverlay: supportsCollarPocketOverlay,
      );

  factory Garment.fromJson(Map<String, dynamic> json) => Garment(
        id: json['id'] as String,
        label: json['label'] as String,
        frontUrl: json['frontImageUrl'] as String?,
        backUrl: json['backImageUrl'] as String?,
        supportsCollarPocketOverlay:
            json['supportsCollarPocket'] as bool? ?? false,
      );
}

class GarmentRegistry {
  GarmentRegistry._();

  // Bundled defaults — used before the backend response arrives and as fallback.
  static const List<Garment> _defaults = [
    Garment(
      id: 'tshirt',
      label: 'T-Shirt',
      frontAsset: 'assets/images/tshirt_white.png',
      backAsset: 'assets/images/tshirt_white.png',
      supportsCollarPocketOverlay: true,
    ),
    Garment(id: 'hoodie',  label: 'Hoodie'),
    Garment(id: 'polo',    label: 'Polo Shirt'),
    Garment(id: 'cap',     label: 'Cap'),
    Garment(id: 'totebag', label: 'Tote Bag'),
  ];

  static List<Garment> _live = List.from(_defaults);

  /// Called once at startup (or when backend data arrives) to replace the
  /// registry entries with CMS-driven values, preserving bundled assets as
  /// fallback for any garment the backend doesn't return.
  static void updateFromBackend(List<Garment> backendGarments) {
    final merged = <Garment>[];
    for (final bg in backendGarments) {
      final def = _defaults.where((d) => d.id == bg.id).firstOrNull;
      merged.add(Garment(
        id: bg.id,
        label: bg.label,
        frontAsset: def?.frontAsset,
        backAsset: def?.backAsset,
        frontUrl: bg.frontUrl,
        backUrl: bg.backUrl,
        supportsCollarPocketOverlay: bg.supportsCollarPocketOverlay,
      ));
    }
    // Keep any local-only garments not returned by the backend.
    for (final d in _defaults) {
      if (!merged.any((g) => g.id == d.id)) merged.add(d);
    }
    _live = merged;
  }

  static List<Garment> get all => _live;

  /// Maps Sanity category slugs / variants onto canonical garment ids.
  static const Map<String, String> _aliases = {
    'shirt': 'tshirt',
    't-shirt': 'tshirt',
    'tshirts': 'tshirt',
    'tee': 'tshirt',
    'hoodies': 'hoodie',
    'polo-shirt': 'polo',
    'polos': 'polo',
    'caps': 'cap',
    'tote': 'totebag',
    'tote-bag': 'totebag',
    'totebags': 'totebag',
  };

  static Garment byId(String id) {
    final key = _aliases[id] ?? id;
    return _live.firstWhere(
      (g) => g.id == key,
      orElse: () => Garment(id: id, label: id),
    );
  }
}
