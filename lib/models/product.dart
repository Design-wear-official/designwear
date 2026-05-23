class Product {
  final String id;
  final String title;
  final String slug;
  final String description;
  final double price;
  final double? originalPrice; // before discount
  final double? discountPercent;
  final String? imageUrl;
  final List<String> images; // all product images
  final String categoryId;
  final String stockStatus;
  final int stockCount;
  final bool featured;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final String? material;
  final String? productType; // 'T-Shirt', 'Hoodie', etc.
  final List<String> availableSizes;
  final List<String> availableColors;

  Product({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    this.imageUrl,
    this.images = const [],
    required this.categoryId,
    required this.stockStatus,
    this.stockCount = 0,
    this.featured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.tags = const [],
    this.material,
    this.productType,
    this.availableSizes = const ['S', 'M', 'L', 'XL', 'XXL'],
    this.availableColors = const [],
  });

  bool get isOnSale => discountPercent != null && discountPercent! > 0;
  bool get isInStock => stockStatus == 'inStock';

  Product copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    double? price,
    double? originalPrice,
    double? discountPercent,
    String? imageUrl,
    List<String>? images,
    String? categoryId,
    String? stockStatus,
    int? stockCount,
    bool? featured,
    double? rating,
    int? reviewCount,
    List<String>? tags,
    String? material,
    String? productType,
    List<String>? availableSizes,
    List<String>? availableColors,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? List.from(this.images),
      categoryId: categoryId ?? this.categoryId,
      stockStatus: stockStatus ?? this.stockStatus,
      stockCount: stockCount ?? this.stockCount,
      featured: featured ?? this.featured,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      tags: tags ?? List.from(this.tags),
      material: material ?? this.material,
      productType: productType ?? this.productType,
      availableSizes: availableSizes ?? List.from(this.availableSizes),
      availableColors: availableColors ?? List.from(this.availableColors),
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final stock = (map['stock'] as num?)?.toInt() ?? 0;
    final rawPrice = map['price'];
    final double price = rawPrice == null
        ? 0.0
        : rawPrice is num
            ? rawPrice.toDouble()
            : double.tryParse(rawPrice.toString()) ?? 0.0;

    final rawOriginal = map['originalPrice'];
    final double? originalPrice = rawOriginal == null
        ? null
        : rawOriginal is num
            ? rawOriginal.toDouble()
            : double.tryParse(rawOriginal.toString());

    double? discountPercent;
    if (originalPrice != null && originalPrice > price && price > 0) {
      discountPercent = ((originalPrice - price) / originalPrice * 100).roundToDouble();
    }

    return Product(
      id: map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      slug: map['slug'] is Map
          ? (map['slug']['current'] ?? '')
          : (map['slug']?.toString() ?? ''),
      description: map['description']?.toString() ?? '',
      price: price,
      originalPrice: originalPrice,
      discountPercent: discountPercent,
      imageUrl: map['imageUrl']?.toString(),
      images: (map['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      categoryId: map['category'] is Map
          ? (map['category']['_ref'] ?? '')
          : (map['category']?.toString() ?? ''),
      stockStatus: stock > 0 ? 'inStock' : 'outOfStock',
      stockCount: stock,
      featured: map['featured'] == true,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      material: map['material']?.toString(),
      productType: map['productType']?.toString(),
      availableSizes: (map['availableSizes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['S', 'M', 'L', 'XL', 'XXL'],
      availableColors: (map['availableColors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  factory Product.fromApiMap(Map<String, dynamic> map) {
    final double price = (map['price'] ?? 0).toDouble();
    final double? originalPrice = map['originalPrice'] != null
        ? (map['originalPrice'] as num).toDouble()
        : null;

    double? discountPercent;
    if (originalPrice != null && originalPrice > price && price > 0) {
      discountPercent = ((originalPrice - price) / originalPrice * 100).roundToDouble();
    }

    return Product(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      slug: map['slug'] ?? '',
      description: map['description'] ?? '',
      price: price,
      originalPrice: originalPrice,
      discountPercent: discountPercent,
      imageUrl: map['imageUrl'],
      images: (map['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      categoryId: map['categoryId'] ?? '',
      stockStatus: map['stockStatus'] ?? 'inStock',
      stockCount: (map['stockCount'] as num?)?.toInt() ?? 0,
      featured: map['featured'] == true,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      material: map['material'],
      productType: map['productType'],
      availableSizes: (map['availableSizes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['S', 'M', 'L', 'XL', 'XXL'],
      availableColors: (map['availableColors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'discountPercent': discountPercent,
      'imageUrl': imageUrl,
      'images': images,
      'categoryId': categoryId,
      'stockStatus': stockStatus,
      'stockCount': stockCount,
      'featured': featured,
      'rating': rating,
      'reviewCount': reviewCount,
      'tags': tags,
      'material': material,
      'productType': productType,
      'availableSizes': availableSizes,
      'availableColors': availableColors,
    };
  }
}
