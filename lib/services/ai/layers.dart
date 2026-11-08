/// One row of a garment's size chart (flat measurements in cm).
class SizeSpec {
  const SizeSpec(this.size, {this.chestCm, this.lengthCm, this.sleeveCm});
  final String size;
  final double? chestCm;
  final double? lengthCm;
  final double? sleeveCm;

  static SizeSpec? fromJson(Map<String, dynamic> j) {
    final s = j['size'];
    if (s is! String || s.isEmpty) return null;
    double? n(Object? v) => v is num ? v.toDouble() : null;
    return SizeSpec(
      s,
      chestCm: n(j['chestCm']),
      lengthCm: n(j['lengthCm']),
      sleeveCm: n(j['sleeveCm']),
    );
  }
}

/// A print area of a garment (front, back, a sleeve…): its size in pixels at [dpi].
class PrintPlacement {
  const PrintPlacement({
    required this.key,
    required this.label,
    required this.width,
    required this.height,
    this.dpi = 300,
    this.technique = '',
    this.provisional = false,
  });

  final String key; // front | back | sleeve_left | sleeve_right | neck_label
  final String label;
  final int width;
  final int height;
  final int dpi;
  final String technique;

  /// The size is an estimate until the print provider confirms it.
  final bool provisional;

  double get widthInches => width / dpi;
  double get heightInches => height / dpi;

  /// "3600 × 4800 px · 12 × 16 in at 300 dpi"
  String get sizeText =>
      '$width × $height px · ${_inch(widthInches)} × ${_inch(heightInches)} in at $dpi dpi';

  static String _inch(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  factory PrintPlacement.fromJson(Map<String, dynamic> j) => PrintPlacement(
    key: '${j['key']}',
    label: '${j['label'] ?? j['key']}',
    width: (j['width'] as num).round(),
    height: (j['height'] as num).round(),
    dpi: (j['dpi'] as num?)?.round() ?? 300,
    technique: '${j['technique'] ?? ''}',
    provisional: j['provisional'] == true,
  );

  /// The studio side a placement belongs to ('front', 'back', 'left', 'right'), or null (neck label).
  static String? sideOf(String key) => switch (key) {
    'front' => 'front',
    'back' => 'back',
    'sleeve_left' => 'left',
    'sleeve_right' => 'right',
    _ => null,
  };
}

/// One transparent artwork layer of a job, for one print area.
class PrintLayer {
  const PrintLayer({
    required this.key,
    required this.side,
    required this.label,
    required this.ok,
    this.reason,
    this.url,
    this.printUrl,
    this.pixelWidth,
    this.pixelHeight,
    this.warnings = const [],
    this.width,
    this.height,
    this.dpi,
    this.provisional = false,
  });

  final String key;
  final String? side; // front | back | left | right
  final String label;
  final bool ok;
  final String? reason;
  final String? url; // the transparent layer picture (signed link)
  final String? printUrl; // the print-size file
  final int? pixelWidth;
  final int? pixelHeight;
  final List<String> warnings;
  final int? width;
  final int? height;
  final int? dpi;
  final bool provisional;

  factory PrintLayer.fromJson(Map<String, dynamic> j) => PrintLayer(
    key: '${j['key']}',
    side: j['side'] as String? ?? PrintPlacement.sideOf('${j['key']}'),
    label: '${j['label'] ?? j['key']}',
    ok: j['status'] == 'ok',
    reason: j['reason'] as String?,
    url: _https(j['url']),
    printUrl: _https(j['printUrl']),
    pixelWidth: (j['pixelWidth'] as num?)?.round(),
    pixelHeight: (j['pixelHeight'] as num?)?.round(),
    warnings: [for (final w in (j['warnings'] as List? ?? const [])) '$w'],
    width: (j['width'] as num?)?.round(),
    height: (j['height'] as num?)?.round(),
    dpi: (j['dpi'] as num?)?.round(),
    provisional: j['provisional'] == true,
  );
}

/// What `POST /v1/ai/design-layers` made: layers per print area plus the signed links to the mock-up
/// views, the contact sheet (PNG and PDF) and a 3-D model.
class LayerJob {
  const LayerJob({
    required this.id,
    required this.name,
    required this.garment,
    required this.layers,
    this.sheetUrl,
    this.sheetPdfUrl,
    this.modelUrl,
    this.views = const {},
    this.complete = false,
  });

  final String id;
  final String name;
  final String garment;
  final List<PrintLayer> layers;
  final String? sheetUrl;
  final String? sheetPdfUrl;
  final String? modelUrl;

  /// 'front' | 'right' | 'back' | 'left' -> picture link.
  final Map<String, String> views;
  final bool complete;

  /// The realistic mock-up for a studio side, or null.
  String? viewFor(String side) => views[side];

  factory LayerJob.fromJson(Map<String, dynamic> j) {
    final urls = (j['urls'] as Map?)?.cast<String, dynamic>() ?? const {};
    final views = (urls['views'] as Map?)?.cast<String, dynamic>() ?? const {};
    return LayerJob(
      id: '${j['id']}',
      name: '${j['name'] ?? ''}',
      garment: '${j['garment'] ?? ''}',
      layers: [
        for (final l in (j['layers'] as List? ?? const []))
          if (l is Map) PrintLayer.fromJson(l.cast<String, dynamic>()),
      ],
      sheetUrl: _https(urls['sheet']),
      sheetPdfUrl: _https(urls['sheetPdf']),
      modelUrl: _https(urls['model']),
      views: {
        for (final e in views.entries)
          if (_https(e.value) != null) e.key: _https(e.value)!,
      },
      complete: j['complete'] == true,
    );
  }
}

/// Signed links are https (or http on a local dev API); anything else is dropped.
String? _https(Object? v) {
  final s = v is String ? v : null;
  if (s == null || s.isEmpty) return null;
  final u = Uri.tryParse(s);
  if (u == null) return null;
  if (u.scheme == 'https') return s;
  if (u.scheme == 'http' && (u.host == 'localhost' || u.host == '127.0.0.1')) {
    return s;
  }
  return null;
}
