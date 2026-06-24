enum DesignElementType {
  text,
  sticker,
  shape,
  image;

  /// Serialised value written to/read from JSON.
  String get value => name;

  static DesignElementType fromString(String v) => switch (v) {
    'sticker' => DesignElementType.sticker,
    'shape'   => DesignElementType.shape,
    'image'   => DesignElementType.image,
    _         => DesignElementType.text,
  };
}

/// Which face of the garment an element lives on.
enum DesignSide {
  front,
  back;

  String get value => name;
  static DesignSide fromString(String? v) =>
      v == 'back' ? DesignSide.back : DesignSide.front;
}

class DesignElement {
  final String id;
  final DesignElementType type;
  /// Text string, emoji, shape name ('rect'|'circle'|'triangle'|'line'), or
  /// base64-encoded PNG bytes for [DesignElementType.image].
  final String content;
  final double x;
  final double y;
  /// Font size (text) / emoji size (sticker). Shapes & images use [width]/[height].
  final double size;
  final String color;
  /// Clockwise rotation in degrees.
  final double rotation;
  /// Box width/height for shape & image elements (logical px). Null for text/sticker.
  final double? width;
  final double? height;
  /// 0.0 (transparent) .. 1.0 (opaque).
  final double opacity;
  /// Which garment face this element is printed on.
  final DesignSide side;
  final Map<String, dynamic> properties;

  DesignElement({
    required this.id,
    this.type = DesignElementType.text,
    this.content = '',
    this.x = 0,
    this.y = 0,
    this.size = 20,
    this.color = '0xFF000000',
    this.rotation = 0,
    this.width,
    this.height,
    this.opacity = 1.0,
    this.side = DesignSide.front,
    this.properties = const {},
  });

  DesignElement copyWith({
    String? id,
    DesignElementType? type,
    String? content,
    double? x,
    double? y,
    double? size,
    String? color,
    double? rotation,
    double? width,
    double? height,
    double? opacity,
    DesignSide? side,
    Map<String, dynamic>? properties,
  }) {
    return DesignElement(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      x: x ?? this.x,
      y: y ?? this.y,
      size: size ?? this.size,
      color: color ?? this.color,
      rotation: rotation ?? this.rotation,
      width: width ?? this.width,
      height: height ?? this.height,
      opacity: opacity ?? this.opacity,
      side: side ?? this.side,
      properties: properties ?? Map.from(this.properties),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'content': content,
      'x': x,
      'y': y,
      'size': size,
      'color': color,
      'rotation': rotation,
      'width': width,
      'height': height,
      'opacity': opacity,
      'side': side.value,
      'properties': properties,
    };
  }

  factory DesignElement.fromJson(Map<String, dynamic> json) {
    return DesignElement(
      id: json['id'] ?? '',
      type: DesignElementType.fromString(json['type'] ?? 'text'),
      content: json['content'] ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      size: (json['size'] as num?)?.toDouble() ?? 20,
      color: json['color'] ?? '0xFF000000',
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      side: DesignSide.fromString(json['side'] as String?),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    );
  }
}

class CustomDesign {
  final String baseColor; // Hex string, e.g., "0xFF000000"
  final String text;
  final double textX;
  final double textY;
  final double fontSize;
  final String textColor; // Hex string
  final String sticker; // Emoji string
  final double stickerX;
  final double stickerY;
  final double stickerSize;
  final List<DesignElement> elements; // Layered design system
  final String templateId;
  final String name; // User-given name for the design
  final String productType; // 'T-Shirt', 'Hoodie', 'Cap', etc.
  final String printLocation; // 'centre_chest', 'left_chest', etc.
  final String? thumbnailPath; // Local path to saved thumbnail
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String collarStyle; // 'crew' | 'vneck' | 'polo'
  final String pocketStyle; // 'none' | 'left' | 'right' | 'both'
  final String trimColor;   // 'auto' or hex '0xFF...' — collar/pocket/cuff accent
  final String sleeveCuff;  // 'none' | 'banded' | 'rolled'
  final String fabricFinish; // 'solid' | 'heather' | 'vintage'
  // Runtime-only: AI-generated design graphic (base64, not persisted to JSON)
  final String? designImageBase64;

  CustomDesign({
    this.baseColor = "0xFFFFFFFF",
    this.text = "",
    this.textX = 0,
    this.textY = 0,
    this.fontSize = 20,
    this.textColor = "0xFF000000",
    this.sticker = "",
    this.stickerX = 0,
    this.stickerY = 0,
    this.stickerSize = 60,
    this.elements = const [],
    this.templateId = '',
    this.name = '',
    this.productType = 'T-Shirt',
    this.printLocation = 'centre_chest',
    this.thumbnailPath,
    this.createdAt,
    this.updatedAt,
    this.collarStyle = 'crew',
    this.pocketStyle = 'none',
    this.trimColor = 'auto',
    this.sleeveCuff = 'none',
    this.fabricFinish = 'solid',
    this.designImageBase64,
  });

  CustomDesign copyWith({
    String? baseColor,
    String? text,
    double? textX,
    double? textY,
    double? fontSize,
    String? textColor,
    String? sticker,
    double? stickerX,
    double? stickerY,
    double? stickerSize,
    List<DesignElement>? elements,
    String? templateId,
    String? name,
    String? productType,
    String? printLocation,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? collarStyle,
    String? pocketStyle,
    String? trimColor,
    String? sleeveCuff,
    String? fabricFinish,
    Object? designImageBase64 = _keepExisting,
  }) {
    return CustomDesign(
      baseColor: baseColor ?? this.baseColor,
      text: text ?? this.text,
      textX: textX ?? this.textX,
      textY: textY ?? this.textY,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      sticker: sticker ?? this.sticker,
      stickerX: stickerX ?? this.stickerX,
      stickerY: stickerY ?? this.stickerY,
      stickerSize: stickerSize ?? this.stickerSize,
      elements: elements ?? List.from(this.elements),
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      productType: productType ?? this.productType,
      printLocation: printLocation ?? this.printLocation,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      collarStyle: collarStyle ?? this.collarStyle,
      pocketStyle: pocketStyle ?? this.pocketStyle,
      trimColor: trimColor ?? this.trimColor,
      sleeveCuff: sleeveCuff ?? this.sleeveCuff,
      fabricFinish: fabricFinish ?? this.fabricFinish,
      designImageBase64: identical(designImageBase64, _keepExisting)
          ? this.designImageBase64
          : designImageBase64 as String?,
    );
  }

  static const Object _keepExisting = Object();

  Map<String, dynamic> toJson() {
    return {
      'baseColor': baseColor,
      'text': text,
      'textX': textX,
      'textY': textY,
      'fontSize': fontSize,
      'textColor': textColor,
      'sticker': sticker,
      'stickerX': stickerX,
      'stickerY': stickerY,
      'stickerSize': stickerSize,
      'elements': elements.map((e) => e.toJson()).toList(),
      'templateId': templateId,
      'name': name,
      'productType': productType,
      'printLocation': printLocation,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'collarStyle': collarStyle,
      'pocketStyle': pocketStyle,
      'trimColor': trimColor,
      'sleeveCuff': sleeveCuff,
      'fabricFinish': fabricFinish,
      // Persisted so saved/published designs keep their AI graphic (was dropped before).
      'designImageBase64': designImageBase64,
    };
  }

  factory CustomDesign.fromJson(Map<String, dynamic> json) {
    return CustomDesign(
      baseColor: json['baseColor'] ?? "0xFFFFFFFF",
      text: json['text'] ?? "",
      textX: (json['textX'] as num?)?.toDouble() ?? 0,
      textY: (json['textY'] as num?)?.toDouble() ?? 0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 20,
      textColor: json['textColor'] ?? "0xFF000000",
      sticker: json['sticker'] ?? "",
      stickerX: (json['stickerX'] as num?)?.toDouble() ?? 0,
      stickerY: (json['stickerY'] as num?)?.toDouble() ?? 0,
      stickerSize: (json['stickerSize'] as num?)?.toDouble() ?? 60,
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) => DesignElement.fromJson(e))
              .toList() ??
          [],
      templateId: json['templateId'] ?? '',
      name: json['name'] ?? '',
      productType: json['productType'] ?? 'T-Shirt',
      printLocation: json['printLocation'] ?? 'centre_chest',
      thumbnailPath: json['thumbnailPath'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      collarStyle: json['collarStyle'] ?? 'crew',
      pocketStyle: json['pocketStyle'] ?? 'none',
      trimColor: json['trimColor'] ?? 'auto',
      sleeveCuff: json['sleeveCuff'] ?? 'none',
      fabricFinish: json['fabricFinish'] ?? 'solid',
      designImageBase64: json['designImageBase64'] as String?,
    );
  }

  // Helper methods for design history and templates
  bool get isEmpty =>
      text.isEmpty && sticker.isEmpty && elements.isEmpty && templateId.isEmpty;

  /// Elements printed on the given garment face, in z-order.
  List<DesignElement> elementsForSide(DesignSide side) =>
      elements.where((e) => e.side == side).toList();

  /// True once any image layer exists (AI-generated or uploaded).
  bool get hasImageElement =>
      elements.any((e) => e.type == DesignElementType.image);

  CustomDesign addElement(DesignElement element) {
    return copyWith(elements: [...elements, element]);
  }

  CustomDesign removeElement(String elementId) {
    return copyWith(
      elements: elements.where((e) => e.id != elementId).toList(),
    );
  }

  CustomDesign updateElement(String elementId, DesignElement newElement) {
    return copyWith(
      elements: elements
          .map((e) => e.id == elementId ? newElement : e)
          .toList(),
    );
  }

  CustomDesign reorderElements(int oldIndex, int newIndex) {
    final list = List<DesignElement>.from(elements);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    return copyWith(elements: list);
  }
}
