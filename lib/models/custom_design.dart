enum DesignElementType {
  text,
  sticker,
  shape;

  /// Serialised value written to/read from JSON.
  String get value => name;

  static DesignElementType fromString(String v) => switch (v) {
    'sticker' => DesignElementType.sticker,
    'shape'   => DesignElementType.shape,
    _         => DesignElementType.text,
  };
}

class DesignElement {
  final String id;
  final DesignElementType type;
  final String content;
  final double x;
  final double y;
  final double size;
  final String color;
  final Map<String, dynamic> properties;

  DesignElement({
    required this.id,
    this.type = DesignElementType.text,
    this.content = '',
    this.x = 0,
    this.y = 0,
    this.size = 20,
    this.color = '0xFF000000',
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
  final String? thumbnailPath; // Local path to saved thumbnail
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.thumbnailPath,
    this.createdAt,
    this.updatedAt,
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
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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
      thumbnailPath: json['thumbnailPath'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  // Helper methods for design history and templates
  bool get isEmpty =>
      text.isEmpty && sticker.isEmpty && elements.isEmpty && templateId.isEmpty;

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
