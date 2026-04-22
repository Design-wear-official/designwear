class Product {
  final String id;
  final String title;
  final String slug;
  final String description;
  final double price;
  final String? imageUrl;
  final String categoryId;
  final String stockStatus;
  final bool featured;

  Product({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.categoryId,
    required this.stockStatus,
    this.featured = false,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    // Sanity returns `stock` as an int and `price` as an int/double.
    // `stockStatus` is a String — derive it from the numeric stock value.
    final stock = (map['stock'] as num?)?.toInt() ?? 0;
    final rawPrice = map['price'];
    final double price = rawPrice == null
        ? 0.0
        : rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice.toString()) ?? 0.0;

    return Product(
      id: map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      slug: map['slug'] is Map
          ? (map['slug']['current'] ?? '')
          : (map['slug']?.toString() ?? ''),
      description: map['description']?.toString() ?? '',
      price: price,
      imageUrl: map['imageUrl']?.toString(),
      categoryId: map['category'] is Map
          ? (map['category']['_ref'] ?? '')
          : (map['category']?.toString() ?? ''),
      stockStatus: stock > 0 ? 'inStock' : 'outOfStock',
      featured: map['featured'] == true,
    );
  }

  /// Factory constructor for API response format (from Next.js API)
  factory Product.fromApiMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      slug: map['slug'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
      categoryId: map['categoryId'] ?? '',
      stockStatus: map['stockStatus'] ?? 'inStock',
      featured: map['featured'] == true,
    );
  }

}
