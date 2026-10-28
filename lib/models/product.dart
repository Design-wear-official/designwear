/// A catalog item as served by the SethuCMS `products` collection.
///
/// The parser accepts both the backend's flat shape (`id`, `slug`,
/// `categoryId`, `stockCount`) and the older Sanity-style shape (`_id`,
/// `slug.current`, `stock`), since the Firestore mirror held both.
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    this.slug = '',
    this.description = '',
    this.originalPrice,
    this.imageUrl,
    this.images = const [],
    this.categoryId = '',
    this.stockCount = 0,
    this.featured = false,
    this.rating = 0,
    this.reviewCount = 0,
    this.tags = const [],
    this.material,
    this.productType,
    this.availableSizes = const ['S', 'M', 'L', 'XL', 'XXL'],
    this.availableColors = const [],
    this.previewImageUrl,
    this.creatorName,
    this.creatorHandle,
    this.remixedFromHandle,
    this.likeCount = 0,
    this.remixCount = 0,
  });

  final String id;
  final String title;
  final String slug;
  final String description;
  final double price;
  final double? originalPrice;
  final String? imageUrl;
  final List<String> images;
  final String categoryId;
  final int stockCount;
  final bool featured;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final String? material;
  final String? productType;
  final List<String> availableSizes;
  final List<String> availableColors;
  final String? previewImageUrl;
  final String? creatorName;
  final String? creatorHandle;
  final String? remixedFromHandle;
  final int likeCount;
  final int remixCount;

  bool get isInStock => stockCount > 0;

  /// 'inStock' or 'outOfStock', the values the product page switches on.
  String get stockStatus => isInStock ? 'inStock' : 'outOfStock';

  /// A community remix of another design, not an original catalog product.
  /// The shop hides these; the remix data stays in the database untouched.
  bool get isRemix =>
      (remixedFromHandle ?? '').isNotEmpty ||
      RegExp(r'^\s*remix by\b', caseSensitive: false).hasMatch(title);

  /// What the shop shows: originals that can actually be sold (price > 0).
  bool get isListable => !isRemix && price > 0;

  double? get discountPercent {
    final original = originalPrice;
    if (original == null || original <= price || price <= 0) return null;
    return ((original - price) / original * 100).roundToDouble();
  }

  bool get isOnSale => discountPercent != null;

  /// Community designs from the Design Studio carry a creator handle.
  bool get isDesignedGarment => (creatorHandle ?? '').isNotEmpty;

  /// Card image: studio canvas snapshot when present, else the catalog photo.
  String? get displayImageUrl =>
      (previewImageUrl ?? '').isNotEmpty ? previewImageUrl : imageUrl;

  factory Product.fromRecord(Map<String, Object?> map) {
    double? num_(Object? v) =>
        v is num ? v.toDouble() : (v == null ? null : double.tryParse('$v'));
    int int_(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    List<String> strings(Object? v) =>
        v is List ? v.map((e) => '$e').toList() : const [];
    String? str(Object? v) {
      final s = v?.toString();
      return (s == null || s.isEmpty) ? null : s;
    }

    final slug = map['slug'];
    final category = map['categoryId'] ?? map['category'];
    final sizes = strings(map['availableSizes']);

    return Product(
      id: '${map['id'] ?? map['_id'] ?? ''}',
      title: '${map['title'] ?? map['name'] ?? ''}',
      slug: slug is Map ? '${slug['current'] ?? ''}' : '${slug ?? ''}',
      description: '${map['description'] ?? ''}',
      price: num_(map['price']) ?? 0,
      originalPrice: num_(map['originalPrice']),
      imageUrl: str(map['imageUrl']),
      images: strings(map['images']),
      categoryId: category is Map
          ? '${category['_ref'] ?? ''}'
          : '${category ?? ''}',
      stockCount: int_(map['stockCount'] ?? map['stock']),
      featured: map['featured'] == true,
      rating: num_(map['rating']) ?? 0,
      reviewCount: int_(map['reviewCount']),
      tags: strings(map['tags']),
      material: str(map['material']),
      productType: str(map['productType']),
      availableSizes: sizes.isEmpty
          ? const ['S', 'M', 'L', 'XL', 'XXL']
          : sizes,
      availableColors: strings(map['availableColors']),
      previewImageUrl: str(map['previewImageUrl']),
      creatorName: str(map['creatorName']),
      creatorHandle: str(map['creatorHandle']),
      remixedFromHandle: str(map['remixedFromHandle']),
      likeCount: int_(map['likeCount']),
      remixCount: int_(map['remixCount']),
    );
  }
}
