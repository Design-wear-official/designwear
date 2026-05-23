class Category {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String? imageUrl;
  final String? iconName; // Material icon name string
  final int productCount;
  final String? parentId;
  final bool featured;

  Category({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    this.imageUrl,
    this.iconName,
    this.productCount = 0,
    this.parentId,
    this.featured = false,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasParent => parentId != null && parentId!.isNotEmpty;

  Category copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    String? imageUrl,
    String? iconName,
    int? productCount,
    String? parentId,
    bool? featured,
  }) {
    return Category(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      iconName: iconName ?? this.iconName,
      productCount: productCount ?? this.productCount,
      parentId: parentId ?? this.parentId,
      featured: featured ?? this.featured,
    );
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['_id'] ?? '',
      title: map['title'] ?? '',
      slug: map['slug']?['current'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      iconName: map['iconName'],
      productCount: (map['productCount'] as num?)?.toInt() ?? 0,
      parentId: map['parent']?['_ref'],
      featured: map['featured'] == true,
    );
  }

  factory Category.fromApiMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      slug: map['slug'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      iconName: map['iconName'],
      productCount: (map['productCount'] as num?)?.toInt() ?? 0,
      parentId: map['parentId'],
      featured: map['featured'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'imageUrl': imageUrl,
      'iconName': iconName,
      'productCount': productCount,
      'parentId': parentId,
      'featured': featured,
    };
  }
}
