import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/services/sanity_service.dart';
import 'package:designwear/services/design_template_service.dart';

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

  // Content endpoints — always served from Sanity CMS
  Future<List<HomeBanner>> fetchBanners() => SanityService().fetchBanners();
  Future<List<Deal>> fetchDeals() => SanityService().fetchDeals();
  Future<List<CategoryQuickLink>> fetchCategoryQuickLinks() => SanityService().fetchCategoryQuickLinks();
  Future<List<DesignTemplate>> fetchDesignTemplates() => SanityService().fetchDesignTemplates();

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
    try {
      return await sanityService.fetchProducts();
    } catch (e) {
      debugPrint('Sanity fetch failed: $e');
      return [];
    }
  }

  Future<List<Category>> _fetchCategoriesFromSanity() async {
    final sanityService = SanityService();
    try {
      return await sanityService.fetchCategories();
    } catch (e) {
      debugPrint('Sanity fetch failed: $e');
      return [];
    }
  }

  Future<List<Product>> _fetchProductsByCategoryFromSanity(
    String categoryId,
  ) async {
    final sanityService = SanityService();
    try {
      return await sanityService.fetchProductsByCategory(categoryId);
    } catch (e) {
      debugPrint('Sanity fetch failed: $e');
      return [];
    }
  }

  Future<Product?> _fetchProductByIdFromSanity(String productId) async {
    try {
      final products = await _fetchProductsFromSanity();
      return products.cast<Product?>().firstWhere(
        (p) => p?.id == productId,
        orElse: () => null,
      );
    } catch (e) {
      debugPrint('Product fetch failed: $e');
      return null;
    }
  }

  Future<List<Product>> _fetchFeaturedProductsFromSanity() async {
    final sanityService = SanityService();
    try {
      return await sanityService.fetchFeaturedProducts();
    } catch (e) {
      debugPrint('Sanity fetch failed: $e');
      return [];
    }
  }

  Future<double> _fetchTaxRateFromSanity() async {
    final sanityService = SanityService();
    return await sanityService.fetchTaxRate();
  }

  /// Publishes a remix design to Sanity and syncs it to Firebase.
  /// Returns the new Sanity product ID on success, throws on failure.
  Future<String> publishRemix({
    required String creatorHandle,
    required String creatorName,
    required String garmentType,
    String? title,
    String? garmentBaseColor,
    String? artText,
    String? remixedFromId,
    String? remixedFromHandle,
    String? remixedFromVersion,
    List<Map<String, String>> lineage = const [],
    List<String> tags = const [],
    // Full serialised CustomDesign so the published product is lossless.
    Map<String, dynamic>? designJson,
    // base64-encoded PNG preview of the rendered canvas (becomes the thumbnail).
    String? previewImageBase64,
  }) async {
    final uri = Uri.parse('${webApiBaseUrl ?? _fallbackBaseUrl}/publish-remix');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'garmentType': garmentType,
            'garmentBaseColor': garmentBaseColor,
            'artText': artText,
            'creatorName': creatorName,
            'creatorHandle': creatorHandle,
            'remixedFromId': remixedFromId,
            'remixedFromHandle': remixedFromHandle,
            'remixedFromVersion': remixedFromVersion,
            'lineage': lineage,
            'tags': tags,
            'designJson': designJson,
            'previewImageBase64': previewImageBase64,
          }),
        )
        .timeout(const Duration(seconds: 45));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return data['productId'] as String;
    }
    throw Exception(data['error'] ?? 'Publish failed (${response.statusCode})');
  }

  static const _fallbackBaseUrl = 'https://designwear-backend.vishwamai.com/api';
}
