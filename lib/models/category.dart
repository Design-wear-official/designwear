class Category {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String? imageUrl;

  Category({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    this.imageUrl,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['_id'] ?? '',
      title: map['title'] ?? '',
      slug: map['slug']?['current'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }

  /// Factory constructor for API response format (from Next.js API)
  factory Category.fromApiMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      slug: map['slug'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }

}
