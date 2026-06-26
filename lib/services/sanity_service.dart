import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_sanity/flutter_sanity.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/services/design_template_service.dart';
import 'package:designwear/config/config.dart';

class SanityService {
  final SanityClient client = SanityClient(
    projectId: SanityConfig.projectId,
    dataset: SanityConfig.dataset,
    useCdn: true,
  );

  // Shared GROQ projection for product fields including community data
  // NOTE: Sanity schema uses "name" not "title"; coalesce handles both.
  // "productType" aliases garmentType so Product.fromMap can read it.
  static const _productProjection = '''
    _id,
    "title": coalesce(title, name),
    "slug": slug.current,
    description, price, featured, tags,
    "imageUrl": coalesce(image.asset->url, images[0].asset->url),
    "images": images[].asset->url,
    category, stock,
    "availableSizes": sizes,
    "availableColors": colors,
    "productType": garmentType,
    creatorName, creatorHandle, creatorFollowers,
    garmentBaseColor, artText,
    remixedFromHandle, remixedFromVersion,
    likeCount, remixCount,
    "lineage": lineage[]{handle, version, baseColor, artText},
    "previewImageUrl": previewImage.asset->url,
    "backPreviewImageUrl": backPreviewImage.asset->url
  ''';

  Future<List<Product>> fetchProducts() async {
    try {
      final query =
          '*[_type == "product"] | order(_updatedAt desc) {$_productProjection}';
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
      final query =
          '*[_type == "product" && featured == true]{$_productProjection}';
      final List<dynamic> result = await client.fetch(query);
      if (result.isNotEmpty) {
        return result.map((item) => Product.fromMap(item)).toList();
      }
      debugPrint(
        'No featured products found in Sanity — falling back to first 6 products',
      );
      final fallbackQuery =
          '*[_type == "product"][0..5]{$_productProjection}';
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
          '*[_type == "category"] | order(title asc) {_id, title, slug, description, "imageUrl": coalesce(image.asset->url, images[0].asset->url)}';
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
          '*[_type == "product" && category._ref == "$categoryId"]{$_productProjection}';
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

  Future<List<HomeBanner>> fetchBanners() async {
    try {
      const query = '*[_type == "homeBanner" && active == true] | order(order asc) '
          '{_id, badge, title, subtitle, ctaLabel, ctaAction, ctaColor, "imageUrl": image.asset->url, order}';
      final List<dynamic> result = await client.fetch(query);
      final banners = result.map((m) => HomeBanner.fromMap(m as Map<String, dynamic>)).toList();
      return banners.isNotEmpty ? banners : HomeBanner.fallbacks;
    } catch (e) {
      debugPrint('Sanity fetchBanners failed: $e');
      return HomeBanner.fallbacks;
    }
  }

  Future<List<Deal>> fetchDeals() async {
    try {
      const query = '*[_type == "deal" && active == true && (expiresAt == null || expiresAt > now())] '
          '| order(_updatedAt desc) {_id, label, originalPrice, salePrice, discountPercent, colorHex, "imageUrl": image.asset->url}';
      final List<dynamic> result = await client.fetch(query);
      final deals = result.map((m) => Deal.fromMap(m as Map<String, dynamic>)).toList();
      return deals.isNotEmpty ? deals : Deal.fallbacks;
    } catch (e) {
      debugPrint('Sanity fetchDeals failed: $e');
      return Deal.fallbacks;
    }
  }

  Future<List<CategoryQuickLink>> fetchCategoryQuickLinks() async {
    try {
      const query =
          '*[_type == "categoryQuickLink" && active == true] | order(order asc) '
          '{_id, label, iconName, colorHex, action, tabIndex, order}';
      final List<dynamic> result = await client.fetch(query);
      return result.map((m) => CategoryQuickLink.fromMap(m as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Sanity fetchCategoryQuickLinks failed: $e');
      return [];
    }
  }

  Future<List<DesignTemplate>> fetchDesignTemplates() async {
    try {
      const query = '*[_type == "designTemplate" && active == true] | order(order asc) '
          '{_id, "templateId": templateId.current, name, description, category, '
          '"thumbnailUrl": thumbnail.asset->url, tags, designData}';
      final List<dynamic> result = await client.fetch(query);
      return result.map((m) {
        final map = m as Map<String, dynamic>;
        CustomDesign design;
        try {
          design = CustomDesign.fromJson(
            jsonDecode(map['designData'] as String? ?? '{}') as Map<String, dynamic>,
          );
        } catch (_) {
          design = CustomDesign(baseColor: '0xFF2C2C2C', elements: []);
        }
        return DesignTemplate(
          id: map['templateId'] as String? ?? map['_id'] as String? ?? '',
          name: map['name'] as String? ?? '',
          description: map['description'] as String? ?? '',
          category: map['category'] as String? ?? 'minimalist',
          thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
          tags: (map['tags'] as List<dynamic>?)?.cast<String>() ?? [],
          design: design,
        );
      }).toList();
    } catch (e) {
      debugPrint('Sanity fetchDesignTemplates failed: $e');
      return [];
    }
  }
}
