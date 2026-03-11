import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/sanity_service.dart';

/// Enhanced API service that works with both the Next.js backend and Sanity directly.
/// When the web API is enabled but unreachable, it automatically falls back to Sanity.
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
      final results = await _fetchProductsFromWeb();
      if (results.isNotEmpty) return results;
      // Auto-fallback to Sanity if web API returns nothing or fails
      debugPrint('Web API returned no products — falling back to Sanity');
      return _fetchProductsFromSanity();
    }
    return _fetchProductsFromSanity();
  }

  Future<List<Product>> fetchFeaturedProducts() async {
    if (useWebApi) {
      // Backend doesn't have a featured endpoint yet — use Sanity directly
      return _fetchFeaturedProductsFromSanity();
    }
    return _fetchFeaturedProductsFromSanity();
  }

  Future<List<Category>> fetchCategories() async {
    if (useWebApi) {
      final results = await _fetchCategoriesFromWeb();
      if (results.isNotEmpty) return results;
      debugPrint('Web API returned no categories — falling back to Sanity');
      return _fetchCategoriesFromSanity();
    }
    return _fetchCategoriesFromSanity();
  }

  Future<List<Product>> fetchProductsByCategory(String categoryId) async {
    if (useWebApi) {
      final results = await _fetchProductsByCategoryFromWeb(categoryId);
      if (results.isNotEmpty) return results;
      debugPrint(
        'Web API returned no products for category — falling back to Sanity',
      );
      return _fetchProductsByCategoryFromSanity(categoryId);
    }
    return _fetchProductsByCategoryFromSanity(categoryId);
  }

  Future<Product?> fetchProductById(String productId) async {
    if (useWebApi) {
      final result = await _fetchProductByIdFromWeb(productId);
      if (result != null) return result;
      debugPrint('Web API returned no product by ID — falling back to Sanity');
      return _fetchProductByIdFromSanity(productId);
    }
    return _fetchProductByIdFromSanity(productId);
  }

  Future<double> fetchTaxRate() async {
    if (useWebApi) {
      return _fetchTaxRateFromWeb();
    } else {
      return _fetchTaxRateFromSanity();
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Web API implementations ─────────────────────────────────────────────

  Future<List<Product>> _fetchProductsFromWeb() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$webApiBaseUrl/products'),
        headers: headers,
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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$webApiBaseUrl/categories'),
        headers: headers,
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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$webApiBaseUrl/categories/$categoryId/products'),
        headers: headers,
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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$webApiBaseUrl/products/$productId'),
        headers: headers,
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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$webApiBaseUrl/settings/tax-rate'),
        headers: headers,
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

  // ── Sanity implementations ──────────────────────────────────────────────

  Future<List<Product>> _fetchProductsFromSanity() async {
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
    final products = await _fetchProductsFromSanity();
    try {
      return products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Product>> _fetchFeaturedProductsFromSanity() async {
    final sanityService = SanityService();
    return await sanityService.fetchFeaturedProducts();
  }

  Future<double> _fetchTaxRateFromSanity() async {
    final sanityService = SanityService();
    return await sanityService.fetchTaxRate();
  }
}
