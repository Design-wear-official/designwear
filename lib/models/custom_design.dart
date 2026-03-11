class DesignElement {
  final String id;
  final String type; // 'text', 'sticker', 'shape'
  final String content;
  final double x;
  final double y;
  final double size;
  final String color;
  final Map<String, dynamic>
  properties; // Additional properties like font, effects, etc.

  DesignElement({
    required this.id,
    required this.type,
    this.content = '',
    this.x = 0,
    this.y = 0,
    this.size = 20,
    this.color = '0xFF000000',
    this.properties = const {},
  });

  DesignElement copyWith({
    String? id,
    String? type,
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
      'type': type,
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
      type: json['type'] ?? 'text',
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
  final List<DesignElement> elements; // New layered design system
  final String templateId; // Template identifier
  final Map<String, dynamic> metadata; // Additional design metadata

  CustomDesign({
    this.baseColor = "0xFFFFFFFF", // Default white
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
    this.metadata = const {},
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
    Map<String, dynamic>? metadata,
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
      metadata: metadata ?? Map.from(this.metadata),
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
      'metadata': metadata,
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
      elements:
          (json['elements'] as List<dynamic>?)
              ?.map((e) => DesignElement.fromJson(e))
              .toList() ??
          [],
      templateId: json['templateId'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  // Helper methods for design history and templates
  bool get isEmpty =>
      text.isEmpty && sticker.isEmpty && elements.isEmpty && templateId.isEmpty;

  bool get hasElements => elements.isNotEmpty;

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

  CustomDesign moveElement(String elementId, int newIndex) {
    final List<DesignElement> newElements = List.from(elements);
    final elementIndex = newElements.indexWhere((e) => e.id == elementId);
    if (elementIndex != -1) {
      final element = newElements.removeAt(elementIndex);
      newElements.insert(newIndex.clamp(0, newElements.length), element);
    }
    return copyWith(elements: newElements);
  }
}
