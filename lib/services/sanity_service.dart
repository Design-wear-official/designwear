import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_sanity/flutter_sanity.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../config/gokwik_config.dart';

class SanityService {
  final SanityClient client = SanityClient(
    projectId: SanityConfig.projectId,
    dataset: SanityConfig.dataset,
    useCdn: true,
  );

  Future<List<Product>> fetchProducts() async {
    try {
      const query =
          '*[_type == "product"]{_id, title, slug, description, price, featured, "imageUrl": image.asset->url, category, stock}';
      final List<dynamic> result = await client.fetch(query);
      return result.map((item) => Product.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Sanity fetch failed: $e');
      return [];
    }
  }

  /// Returns only products marked as featured == true.
  /// Falls back to the first 6 products if none are marked featured.
  Future<List<Product>> fetchFeaturedProducts() async {
    try {
      const query =
          '*[_type == "product" && featured == true]{_id, title, slug, description, price, featured, "imageUrl": image.asset->url, category, stock}';
      final List<dynamic> result = await client.fetch(query);
      if (result.isNotEmpty) {
        return result.map((item) => Product.fromMap(item)).toList();
      }
      // If no products are marked featured yet, show the first 6 as a fallback
      debugPrint(
        'No featured products found in Sanity — falling back to first 6 products',
      );
      const fallbackQuery =
          '*[_type == "product"][0..5]{_id, title, slug, description, price, featured, "imageUrl": image.asset->url, category, stock}';
      final List<dynamic> fallback = await client.fetch(fallbackQuery);
      return fallback.map((item) => Product.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Sanity fetch failed: $e');
      return [];
    }
  }

  Future<List<Category>> fetchCategories() async {
    try {
      const query =
          '*[_type == "category"]{_id, title, slug, description, "imageUrl": image.asset->url}';
      final List<dynamic> result = await client.fetch(query);
      return result.map((item) => Category.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Sanity fetch failed: $e');
      return [];
    }
  }

  Future<List<Product>> fetchProductsByCategory(String categoryId) async {
    try {
      final query =
          '*[_type == "product" && category._ref == "$categoryId"]{_id, title, slug, description, price, featured, "imageUrl": image.asset->url, category, stock}';
      final List<dynamic> result = await client.fetch(query);
      return result.map((item) => Product.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Sanity fetch failed: $e');
      return [];
    }
  }

  Future<double> fetchTaxRate() async {
    try {
      const query = '*[_type == "settings"][0].taxRate';
      final result = await client.fetch(query);
      return (result as num?)?.toDouble() ?? 18.0;
    } catch (e) {
      debugPrint('Sanity fetch failed: $e. Returning default tax rate.');
      return 18.0;
    }
  }
}
