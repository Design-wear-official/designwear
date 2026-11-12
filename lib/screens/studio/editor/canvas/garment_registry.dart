import 'package:designwear/models/models.dart';
import 'package:designwear/services/ai/layers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

/// A natural shirt colour the business offers for a garment.
class GarmentColor {
  const GarmentColor(this.name, this.color);
  final String name;
  final Color color;

  /// {name, hex '#1C1C1E'}; null when the hex is not a colour.
  static GarmentColor? fromJson(Map<String, dynamic> j) {
    final hex = '${j['hex'] ?? ''}'.replaceFirst('#', '');
    if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) return null;
    return GarmentColor(
      '${j['name'] ?? '#$hex'}',
      Color(0xFF000000 | int.parse(hex, radix: 16)),
    );
  }
}

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

  /// Starting price from the business's garment list, when it set one.
  final double? basePrice;

  /// The print areas of this garment (size in px at a dpi), when the business's list has them.
  final List<PrintPlacement> placements;

  /// crew, vneck, scoop, henley, polo, raglan, longsleeve, tank, oversized…
  final String style;

  /// The shirt colours to offer in the colour picker (empty: the app's own list).
  final List<GarmentColor> colors;

  /// The size chart, when the business's list has one.
  final List<SizeSpec> sizes;

  /// A tank top has no sleeves, so the sleeve sides are hidden.
  bool get hasSleeves => style != 'tank';

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
    this.basePrice,
    this.placements = const [],
    this.style = 'crew',
    this.colors = const [],
    this.sizes = const [],
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
    basePrice: basePrice,
    placements: placements,
    style: style,
    colors: colors,
    sizes: sizes,
  );

  factory Garment.fromJson(Map<String, dynamic> json) => Garment(
    id: json['id'] as String,
    label: json['label'] as String,
    frontUrl: json['frontImageUrl'] as String?,
    backUrl: json['backImageUrl'] as String?,
    leftUrl: json['leftImageUrl'] as String?,
    rightUrl: json['rightImageUrl'] as String?,
    supportsCollarPocketOverlay: json['supportsCollarPocket'] as bool? ?? false,
    basePrice: (json['basePrice'] as num?)?.toDouble(),
    placements: [
      for (final p in (json['placements'] as List? ?? const []))
        if (p is Map) ?_placement(p.cast<String, dynamic>()),
    ],
    style: (json['style'] as String?)?.toLowerCase() ?? 'crew',
    sizes: [
      for (final s in (json['sizes'] as List? ?? const []))
        if (s is Map) ?SizeSpec.fromJson(s.cast<String, dynamic>()),
    ],
    colors: [
      for (final c in (json['colors'] as List? ?? const []))
        if (c is Map) ?GarmentColor.fromJson(c.cast<String, dynamic>()),
    ],
  );

  static PrintPlacement? _placement(Map<String, dynamic> p) {
    try {
      return PrintPlacement.fromJson(p);
    } catch (_) {
      return null;
    }
  }

  /// The print area for a studio side ('front'…), if known.
  PrintPlacement? placementFor(DesignSide side) {
    final key = switch (side) {
      DesignSide.front => 'front',
      DesignSide.back => 'back',
      DesignSide.left => 'sleeve_left',
      DesignSide.right => 'sleeve_right',
      DesignSide.leftPocket => 'pocket_left',
      DesignSide.rightPocket => 'pocket_right',
    };
    return placements.where((p) => p.key == key).firstOrNull;
  }
}

class GarmentRegistry {
  GarmentRegistry._();

  // The one garment the app ships: used before the backend's list arrives and as the fallback. Every
  // other garment (hoodie, polo, cap...) comes from the business's list in SethuCMS.
  static const List<Garment> _defaults = [
    Garment(
      id: 'tshirt',
      label: 'T-Shirt',
      frontAsset: 'assets/images/garments/crew_front.webp',
      backAsset: 'assets/images/garments/crew_back.webp',
    ),
  ];

  /// Shirt colours offered until the business's list (which carries each garment's colours) has arrived.
  static const List<GarmentColor> fallbackColors = [
    GarmentColor('White', Color(0xFFF4F2EC)),
    GarmentColor('Black', Color(0xFF1C1C1E)),
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
          basePrice: bg.basePrice,
          placements: bg.placements,
          style: bg.style,
          colors: bg.colors,
          sizes: bg.sizes,
        ),
      );
    }
    // Keep any local-only garments not returned by the backend.
    for (final d in _defaults) {
      if (!merged.any((g) => g.id == d.id)) merged.add(d);
    }
    _live = merged;
    _backendIds = {for (final g in backendGarments) g.id};
    revision.value++;
  }

  static Set<String>? _backendIds;

  /// Bumps whenever the list changes, so the chooser can rebuild.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  /// What the studio's garment chooser offers: the business's own list once it has arrived, until
  /// then only the garments the app can already draw.
  static List<Garment> get selectable {
    final ids = _backendIds;
    if (ids == null) {
      return _live.where((g) => g.hasAsset(DesignSide.front)).toList();
    }
    return _live.where((g) => ids.contains(g.id)).toList();
  }

  /// Back to the bundled list (tests).
  @visibleForTesting
  static void reset() {
    _live = List.from(_defaults);
    _backendIds = null;
    revision.value++;
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
