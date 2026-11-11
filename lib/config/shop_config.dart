import 'package:flutter_dotenv/flutter_dotenv.dart';

/// The shop's tunable numbers and labels, in one place. Each is one line:
/// change the default here, or set the named key in `.env`.
/// Keep these in step with the DesignWear API's own settings of the same name.
class ShopConfig {
  ShopConfig._();

  /// GST added in the cart estimate (the API prices the real order). TAX_RATE.
  static double get taxRate => _number('TAX_RATE', 0.18);

  /// Clothing sizes offered when a product lists none. CLOTHING_SIZES, comma-separated.
  static List<String> get clothingSizes =>
      _list('CLOTHING_SIZES', ['S', 'M', 'L', 'XL', 'XXL']);

  /// Sent as the size of a product with nothing to pick. ONE_SIZE_LABEL.
  static String get oneSizeLabel => _text('ONE_SIZE_LABEL', 'One size');

  /// "Only 3 left" is shown at or below this many units. LOW_STOCK_AT.
  static int get lowStockAt => _number('LOW_STOCK_AT', 5).round();

  /// Products loaded for the home page and for search. CATALOG_PAGE_SIZE.
  static int get catalogPageSize => _number('CATALOG_PAGE_SIZE', 40).round();
  static int get searchPageSize => _number('SEARCH_PAGE_SIZE', 200).round();

  /// Watch case diameters (mm) where "small", "medium" and "large" begin and end.
  /// WATCH_SMALL_BELOW_MM, WATCH_LARGE_ABOVE_MM; the filter groups use the same two.
  static double get watchSmallBelowMm => _number('WATCH_SMALL_BELOW_MM', 38);
  static double get watchLargeAboveMm => _number('WATCH_LARGE_ABOVE_MM', 42);

  static String _text(String key, String fallback) {
    try {
      final v = (dotenv.env[key] ?? '').trim();
      return v.isEmpty ? fallback : v;
    } catch (_) {
      return fallback; // dotenv not loaded (tests)
    }
  }

  static double _number(String key, double fallback) =>
      double.tryParse(_text(key, '')) ?? fallback;

  static List<String> _list(String key, List<String> fallback) {
    final parts = _text(
      key,
      '',
    ).split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? fallback : parts;
  }
}
