import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_sanity/flutter_sanity.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../config/gokwik_config.dart';

class SanityService {
  final SanityClient client = SanityClient(
    projectId: SanityConfig.projectId,
    dataset: SanityConfig.dataset,
    useCdn: false,
  );

  Future<List<Product>> fetchProducts() async {
    try {
      const query =
          '*[_type == "product"]{_id, title, slug, description, price, "imageUrl": image.asset->url, category, stock}';
      final List<dynamic> result = await client.fetch(query);
      return result.map((item) => Product.fromMap(item)).toList();
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
          '*[_type == "product" && category._ref == "$categoryId"]{_id, title, slug, description, price, "imageUrl": image.asset->url, category, stock}';
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
