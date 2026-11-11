import '../config/shop_config.dart';
import 'product.dart';

/// What a watch listing carries that a garment does not: case, strap,
/// movement, water resistance and warranty.
///
/// Read from the product record's `watch` object. Every field is optional, so
/// a half-filled CMS entry still shows what it has.
class WatchSpecs {
  const WatchSpecs({
    this.brand,
    this.gender,
    this.caseSizeMm,
    this.caseThicknessMm,
    this.caseShape,
    this.caseMaterial,
    this.dialColor,
    this.glass,
    this.strapMaterial,
    this.strapColor,
    this.strapWidthMm,
    this.movement,
    this.display,
    this.waterResistanceM,
    this.warrantyMonths,
    this.countryOfOrigin,
    this.inTheBox = const [],
  });

  final String? brand;

  /// "Men", "Women" or "Unisex".
  final String? gender;

  /// Case diameter in millimetres, without the crown.
  final double? caseSizeMm;
  final double? caseThicknessMm;
  final String? caseShape;
  final String? caseMaterial;
  final String? dialColor;

  /// Crystal over the dial: "Mineral", "Sapphire", "Acrylic".
  final String? glass;
  final String? strapMaterial;
  final String? strapColor;

  /// Strap width where it meets the case (lug width), in millimetres.
  final double? strapWidthMm;

  /// "Quartz", "Automatic", "Mechanical", "Solar".
  final String? movement;

  /// "Analog", "Digital" or "Analog-Digital".
  final String? display;

  /// Rated water resistance in metres (30 m = 3 ATM = 3 bar).
  final int? waterResistanceM;
  final int? warrantyMonths;
  final String? countryOfOrigin;
  final List<String> inTheBox;

  bool get isEmpty => specRows.isEmpty && inTheBox.isEmpty;

  /// One line for cards and search rows: "40 mm · Quartz · Leather strap".
  String get summary => [
    if (caseSizeMm != null) '${_fmtMm(caseSizeMm!)} mm',
    ?movement,
    if (strapMaterial != null) '$strapMaterial strap',
  ].join(' · ');

  /// "30 m (3 ATM)", or null when the record has no rating.
  String? get waterResistanceLabel {
    final m = waterResistanceM;
    if (m == null) return null;
    if (m <= 0) return 'Not water resistant';
    return m % 10 == 0 ? '$m m (${m ~/ 10} ATM)' : '$m m';
  }

  /// What the rating allows in daily use. The depth on the dial is a static
  /// pressure test (ISO 22810), not a depth the watch can be taken to.
  String? get waterResistanceAdvice {
    final m = waterResistanceM;
    if (m == null) return null;
    if (m <= 0) return 'Keep it away from water.';
    if (m < 50) {
      return 'Fine with rain and hand washing. Take it off to shower or swim.';
    }
    if (m < 100) {
      return 'Fine with rain, splashes and hand washing. Check the manual before swimming.';
    }
    if (m < 200) {
      return 'Fine for swimming and snorkelling. Not for scuba diving.';
    }
    return 'Fine for swimming, snorkelling and recreational diving.';
  }

  /// "1 year", "18 months", "2 years".
  String? get warrantyLabel {
    final months = warrantyMonths;
    if (months == null || months <= 0) return null;
    if (months % 12 != 0) return '$months months';
    final years = months ~/ 12;
    return years == 1 ? '1 year' : '$years years';
  }

  /// Which wrists the case suits, from its diameter.
  String? get fitAdvice {
    final mm = caseSizeMm;
    if (mm == null) return null;
    final size = _fmtMm(mm);
    if (mm < 34) {
      return 'A $size mm case is small. It suits slim wrists up to about 15 cm around.';
    }
    if (mm < 38) {
      return 'A $size mm case is on the smaller side. It suits wrists of about 14 to 16 cm.';
    }
    if (mm <= 42) {
      return 'A $size mm case is mid-sized. It suits most wrists, about 15 to 18 cm around.';
    }
    if (mm <= 46) {
      return 'A $size mm case is large. It suits wrists of about 17 cm and above.';
    }
    return 'A $size mm case is oversized. It suits wrists of about 19 cm and above.';
  }

  /// The specification table, in the order shoppers read it. Rows without a
  /// value are left out.
  List<(String, String)> get specRows => [
    if (brand != null) ('Brand', brand!),
    if (gender != null) ('For', gender!),
    if (caseSizeMm != null) ('Case size', '${_fmtMm(caseSizeMm!)} mm'),
    if (caseThicknessMm != null)
      ('Case thickness', '${_fmtMm(caseThicknessMm!)} mm'),
    if (caseShape != null) ('Case shape', caseShape!),
    if (caseMaterial != null) ('Case material', caseMaterial!),
    if (dialColor != null) ('Dial colour', dialColor!),
    if (glass != null) ('Glass', glass!),
    if (strapMaterial != null) ('Strap material', strapMaterial!),
    if (strapColor != null) ('Strap colour', strapColor!),
    if (strapWidthMm != null) ('Strap width', '${_fmtMm(strapWidthMm!)} mm'),
    if (movement != null) ('Movement', movement!),
    if (display != null) ('Display', display!),
    if (waterResistanceLabel != null)
      ('Water resistance', waterResistanceLabel!),
    if (warrantyLabel != null) ('Warranty', warrantyLabel!),
    if (countryOfOrigin != null) ('Country of origin', countryOfOrigin!),
  ];

  /// Words a search for this watch should match.
  Iterable<String> get searchTerms => [
    'watch',
    ?brand,
    ?gender,
    ?caseMaterial,
    ?dialColor,
    ?strapMaterial,
    ?strapColor,
    ?movement,
    ?display,
  ];

  /// Parses the `watch` object of a product record. Numbers may arrive as
  /// strings ("40", "40 mm"), and the older key spellings are accepted.
  factory WatchSpecs.fromRecord(Map<String, Object?> map) {
    String? str(List<String> keys) {
      for (final k in keys) {
        final s = map[k]?.toString().trim();
        if (s != null && s.isNotEmpty) return s;
      }
      return null;
    }

    double? number(List<String> keys) {
      for (final k in keys) {
        final v = map[k];
        if (v is num) return v.toDouble();
        final match = RegExp(r'\d+(\.\d+)?').firstMatch('${v ?? ''}');
        if (match != null) return double.parse(match.group(0)!);
      }
      return null;
    }

    final box = map['inTheBox'] ?? map['boxContents'];
    return WatchSpecs(
      brand: str(['brand']),
      gender: str(['gender']),
      caseSizeMm: number(['caseSizeMm', 'caseDiameterMm', 'caseSize']),
      caseThicknessMm: number(['caseThicknessMm', 'caseThickness']),
      caseShape: str(['caseShape']),
      caseMaterial: str(['caseMaterial']),
      dialColor: str(['dialColor', 'dialColour']),
      glass: str(['glass', 'crystal']),
      strapMaterial: str(['strapMaterial', 'bandMaterial']),
      strapColor: str(['strapColor', 'strapColour', 'bandColor']),
      strapWidthMm: number(['strapWidthMm', 'bandWidthMm', 'lugWidthMm']),
      movement: str(['movement']),
      display: str(['display', 'displayType']),
      waterResistanceM: number(['waterResistanceM', 'waterResistance'])
          ?.round(),
      warrantyMonths: number(['warrantyMonths'])?.round(),
      countryOfOrigin: str(['countryOfOrigin']),
      inTheBox: box is List ? [for (final e in box) '$e'] : const [],
    );
  }
}

/// A group of case sizes shoppers filter by.
enum CaseSizeBand {
  small,
  medium,
  large;

  /// "Under 38 mm", "38 to 42 mm", "Over 42 mm"; the limits are in ShopConfig.
  String get label {
    final low = _fmtMm(ShopConfig.watchSmallBelowMm);
    final high = _fmtMm(ShopConfig.watchLargeAboveMm);
    return switch (this) {
      small => 'Under $low mm',
      medium => '$low to $high mm',
      large => 'Over $high mm',
    };
  }

  static CaseSizeBand? of(double? mm) => mm == null
      ? null
      : mm < ShopConfig.watchSmallBelowMm
      ? small
      : mm <= ShopConfig.watchLargeAboveMm
      ? medium
      : large;
}

/// The facets watches are filtered by on the listing.
enum WatchFacet {
  gender('For'),
  strap('Strap'),
  dial('Dial colour'),
  movement('Movement'),
  caseSize('Case size'),
  origin('Country of origin');

  const WatchFacet(this.label);
  final String label;

  /// This watch's value for the facet, or null when the record lacks it.
  String? valueOf(WatchSpecs w) => switch (this) {
    gender => w.gender,
    strap => w.strapMaterial,
    dial => w.dialColor,
    movement => w.movement,
    caseSize => CaseSizeBand.of(w.caseSizeMm)?.label,
    origin => w.countryOfOrigin,
  };
}

/// The filters chosen on the watches listing. Values within one facet are
/// alternatives (leather OR steel); facets combine (leather AND quartz).
class WatchFilter {
  const WatchFilter([this.selected = const {}]);

  final Map<WatchFacet, Set<String>> selected;

  bool get isEmpty => selected.values.every((v) => v.isEmpty);
  int get count => selected.values.fold(0, (n, v) => n + v.length);

  bool isSelected(WatchFacet facet, String value) =>
      selected[facet]?.contains(_norm(value)) ?? false;

  /// A copy with [value] switched on or off for [facet].
  WatchFilter toggle(WatchFacet facet, String value) {
    final v = _norm(value);
    final values = {...?selected[facet]};
    values.contains(v) ? values.remove(v) : values.add(v);
    return WatchFilter({...selected, facet: values});
  }

  bool matches(Product product) {
    final w = product.watch;
    if (w == null) return false;
    for (final MapEntry(key: facet, value: values) in selected.entries) {
      if (values.isEmpty) continue;
      final value = facet.valueOf(w);
      if (value == null || !values.contains(_norm(value))) return false;
    }
    return true;
  }

  /// The values each facet can take across [products], in display spelling.
  /// A facet with fewer than two values is left out: it filters nothing.
  static Map<WatchFacet, List<String>> options(Iterable<Product> products) {
    final out = <WatchFacet, List<String>>{};
    for (final facet in WatchFacet.values) {
      final seen = <String, String>{};
      for (final p in products) {
        final w = p.watch;
        final value = w == null ? null : facet.valueOf(w);
        if (value != null) seen.putIfAbsent(_norm(value), () => value);
      }
      if (seen.length < 2) continue;
      out[facet] = facet == WatchFacet.caseSize
          ? [
              for (final band in CaseSizeBand.values)
                if (seen.containsKey(_norm(band.label))) band.label,
            ]
          : (seen.values.toList()..sort());
    }
    return out;
  }

  static String _norm(String s) => s.trim().toLowerCase();
}

String _fmtMm(double v) =>
    v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
