import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/category.dart';
import '../services/sanity_service.dart';

/// Enhanced API service that can work with both Sanity directly and Next.js API
class ApiService {
  final String? webApiBaseUrl;
  final bool useWebApi;

  ApiService({this.webApiBaseUrl, this.useWebApi = false});

  /// Factory constructor for web API mode
  factory ApiService.webApi(String baseUrl) {
    return ApiService(webApiBaseUrl: baseUrl, useWebApi: true);
  }

  /// Factory constructor for direct Sanity mode (default)
  factory ApiService.sanity() {
    return ApiService(useWebApi: false);
  }

  Future<List<Product>> fetchProducts() async {
    if (useWebApi) {
      return _fetchProductsFromWeb();
    } else {
      return _fetchProductsFromSanity();
    }
  }

  Future<List<Category>> fetchCategories() async {
    if (useWebApi) {
      return _fetchCategoriesFromWeb();
    } else {
      return _fetchCategoriesFromSanity();
    }
  }

  Future<List<Product>> fetchProductsByCategory(String categoryId) async {
    if (useWebApi) {
      return _fetchProductsByCategoryFromWeb(categoryId);
    } else {
      return _fetchProductsByCategoryFromSanity(categoryId);
    }
  }

  Future<Product?> fetchProductById(String productId) async {
    if (useWebApi) {
      return _fetchProductByIdFromWeb(productId);
    } else {
      return _fetchProductByIdFromSanity(productId);
    }
  }

  Future<double> fetchTaxRate() async {
    if (useWebApi) {
      return _fetchTaxRateFromWeb();
    } else {
      return _fetchTaxRateFromSanity();
    }
  }

  // Web API implementations
  Future<List<Product>> _fetchProductsFromWeb() async {
    try {
      final response = await http.get(
        Uri.parse('$webApiBaseUrl/products'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> products = data['data'];
          return products.map((item) => Product.fromApiMap(item)).toList();
        }
      }
      debugPrint('Web API fetch failed: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Web API fetch failed: $e');
      return [];
    }
  }

  Future<List<Category>> _fetchCategoriesFromWeb() async {
    try {
      final response = await http.get(
        Uri.parse('$webApiBaseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> categories = data['data'];
          return categories.map((item) => Category.fromApiMap(item)).toList();
        }
      }
      debugPrint('Web API fetch failed: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Web API fetch failed: $e');
      return [];
    }
  }

  Future<List<Product>> _fetchProductsByCategoryFromWeb(
    String categoryId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$webApiBaseUrl/categories/$categoryId/products'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> products = data['data'];
          return products.map((item) => Product.fromApiMap(item)).toList();
        }
      }
      debugPrint('Web API fetch failed: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Web API fetch failed: $e');
      return [];
    }
  }

  Future<Product?> _fetchProductByIdFromWeb(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$webApiBaseUrl/products/$productId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Product.fromApiMap(data['data']);
        }
      }
      debugPrint('Web API fetch failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Web API fetch failed: $e');
      return null;
    }
  }

  Future<double> _fetchTaxRateFromWeb() async {
    try {
      final response = await http.get(
        Uri.parse('$webApiBaseUrl/settings/tax-rate'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data']['taxRate'] ?? 18.0).toDouble();
        }
      }
      debugPrint('Web API fetch failed: ${response.statusCode}');
      return 18.0;
    } catch (e) {
      debugPrint('Web API fetch failed: $e');
      return 18.0;
    }
  }

  // Sanity implementations (using existing SanityService)
  Future<List<Product>> _fetchProductsFromSanity() async {
    // Import and use the existing SanityService
    final sanityService = SanityService();
    return await sanityService.fetchProducts();
  }

  Future<List<Category>> _fetchCategoriesFromSanity() async {
    final sanityService = SanityService();
    return await sanityService.fetchCategories();
  }

  Future<List<Product>> _fetchProductsByCategoryFromSanity(
    String categoryId,
  ) async {
    final sanityService = SanityService();
    return await sanityService.fetchProductsByCategory(categoryId);
  }

  Future<Product?> _fetchProductByIdFromSanity(String productId) async {
    // This method doesn't exist in original SanityService, so we'll implement it
    final products = await _fetchProductsFromSanity();
    try {
      return products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  Future<double> _fetchTaxRateFromSanity() async {
    final sanityService = SanityService();
    return await sanityService.fetchTaxRate();
  }
}
