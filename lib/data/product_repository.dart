import 'package:sethucms/sethucms.dart';

import '../api/api_client.dart';
import '../cms/cms_service.dart';
import '../logging/app_log.dart';
import '../models/product.dart';

/// Reads the public catalog.
///
/// With the DesignWear API configured, products come from it: browsers can't
/// call the CMS gateway directly (CORS), and the CMS token then never has to
/// ship in the app. If the API can't be reached, the repository falls back to
/// the CMS directly when that is configured (fine on phones and desktop).
class ProductRepository {
  ProductRepository({CmsService? cms, ApiClient? api})
    : assert(cms != null || api != null, 'Needs the API or the CMS'),
      _cms = cms,
      _api = api;

  /// The repository for the running app, or null when neither source is set up.
  static ProductRepository? resolve({ApiClient? api, CmsService? cms}) =>
      (api == null && cms == null)
      ? null
      : ProductRepository(api: api, cms: cms);

  final CmsService? _cms;
  final ApiClient? _api;

  Collection get _products => _cms!.collection('products');

  List<Product> _listable(Iterable<Map<String, Object?>> records) =>
      records.map(Product.fromRecord).where((p) => p.isListable).toList();

  /// Runs [fromApi]; on a network or server failure, [fromCms] if available.
  Future<T> _either<T>(
    Future<T> Function(ApiClient api) fromApi,
    Future<T> Function(CmsService cms) fromCms,
  ) async {
    final api = _api;
    final cms = _cms;
    if (api != null) {
      try {
        return await fromApi(api);
      } on ApiException catch (e) {
        if (cms == null) rethrow;
        AppLog.instance.warning(
          'catalog',
          'API catalog failed (${e.code}); using the CMS directly',
        );
      }
    }
    return fromCms(cms!);
  }

  /// Original, sellable products. Remixes and unpriced entries are dropped
  /// here, so every screen that uses the repository stays clean.
  Future<List<Product>> list({int limit = 40}) => _either(
    (api) async {
      final j = await api.get('/v1/products', query: {'limit': '$limit'});
      return _listable([
        for (final r in (j['data'] as List)) (r as Map).cast<String, Object?>(),
      ]);
    },
    (_) async {
      final page = await _products.query().limit(limit).list();
      return _listable(page.data);
    },
  );

  Future<List<Product>> featured({int limit = 10}) => _either(
    (api) async {
      final j = await api.get(
        '/v1/products',
        query: {'limit': '$limit', 'featured': '1'},
      );
      return _listable([
        for (final r in (j['data'] as List)) (r as Map).cast<String, Object?>(),
      ]);
    },
    (_) async {
      final page = await _products
          .where(eq('featured', true))
          .limit(limit)
          .list();
      return _listable(page.data);
    },
  );

  Future<Product> get(String id) => _either(
    (api) async => Product.fromRecord(
      ((await api.get('/v1/products/${Uri.encodeComponent(id)}'))['data']
              as Map)
          .cast<String, Object?>(),
    ),
    (_) async => Product.fromRecord(await _products.get(id)),
  );
}
