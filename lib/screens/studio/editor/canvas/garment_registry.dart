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
  final String? leftAsset;
  final String? rightAsset;
  // Network URLs fetched from the backend CMS; override bundled assets when set.
  final String? frontUrl;
  final String? backUrl;
  final String? leftUrl;
  final String? rightUrl;
  final bool supportsCollarPocketOverlay;

  const Garment({
    required this.id,
    required this.label,
    this.frontAsset,
    this.backAsset,
    this.leftAsset,
    this.rightAsset,
    this.frontUrl,
    this.backUrl,
    this.leftUrl,
    this.rightUrl,
    this.supportsCollarPocketOverlay = false,
  });

  /// Returns the network URL for [side] if available, otherwise the local asset path.
  String? imageUrl(DesignSide side) => switch (side) {
    DesignSide.back => backUrl ?? backAsset,
    DesignSide.left => leftUrl ?? leftAsset,
    DesignSide.right => rightUrl ?? rightAsset,
    _ => frontUrl ?? frontAsset,
  };

  /// Whether to load [side] from the network (vs. a bundled asset).
  bool isNetworkImage(DesignSide side) => switch (side) {
    DesignSide.back => backUrl != null,
    DesignSide.left => leftUrl != null,
    DesignSide.right => rightUrl != null,
    _ => frontUrl != null,
  };

  /// Backwards-compat helper — true when any image source is available.
  bool hasAsset(DesignSide side) => imageUrl(side) != null;

  Garment withUrls({
    String? frontUrl,
    String? backUrl,
    String? leftUrl,
    String? rightUrl,
  }) => Garment(
    id: id,
    label: label,
    frontAsset: frontAsset,
    backAsset: backAsset,
    leftAsset: leftAsset,
    rightAsset: rightAsset,
    frontUrl: frontUrl ?? this.frontUrl,
    backUrl: backUrl ?? this.backUrl,
    leftUrl: leftUrl ?? this.leftUrl,
    rightUrl: rightUrl ?? this.rightUrl,
    supportsCollarPocketOverlay: supportsCollarPocketOverlay,
  );

  factory Garment.fromJson(Map<String, dynamic> json) => Garment(
    id: json['id'] as String,
    label: json['label'] as String,
    frontUrl: json['frontImageUrl'] as String?,
    backUrl: json['backImageUrl'] as String?,
    leftUrl: json['leftImageUrl'] as String?,
    rightUrl: json['rightImageUrl'] as String?,
    supportsCollarPocketOverlay: json['supportsCollarPocket'] as bool? ?? false,
  );
}

class GarmentRegistry {
  GarmentRegistry._();

  // Bundled defaults — used before the backend response arrives and as fallback.
  static const List<Garment> _defaults = [
    Garment(
      id: 'tshirt',
      label: 'T-Shirt',
      frontAsset: 'assets/images/garments/crew_front.png',
      backAsset: 'assets/images/garments/crew_back.png',
      // Front/back come from the style photos; sleeves and pockets are drawn.
    ),
    Garment(id: 'hoodie', label: 'Hoodie'),
    Garment(id: 'polo', label: 'Polo Shirt'),
    Garment(id: 'cap', label: 'Cap'),
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
      merged.add(
        Garment(
          id: bg.id,
          label: bg.label,
          frontAsset: def?.frontAsset,
          backAsset: def?.backAsset,
          leftAsset: def?.leftAsset,
          rightAsset: def?.rightAsset,
          frontUrl: bg.frontUrl,
          backUrl: bg.backUrl,
          leftUrl: bg.leftUrl,
          rightUrl: bg.rightUrl,
          supportsCollarPocketOverlay: bg.supportsCollarPocketOverlay,
        ),
      );
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
