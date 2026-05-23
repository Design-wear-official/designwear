/// App-wide constants that don't belong in environment config.
class AppConstants {
  AppConstants._();

  // ── App identity ─────────────────────────────────────────────────────────
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appDisplayName = 'DesignWear';
  static const String supportEmail = 'support@designwear.app';
  static const String privacyPolicyUrl = 'https://designwear.app/privacy';
  static const String termsUrl = 'https://designwear.app/terms';

  // ── Product constants ─────────────────────────────────────────────────────
  static const List<String> availableSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
  static const List<String> productTypes = ['T-Shirt', 'Hoodie', 'Polo', 'Cap', 'Tote Bag'];
  static const int maxCartQuantityPerItem = 10;
  static const int maxImagesPerProduct = 8;

  // ── Design Studio ─────────────────────────────────────────────────────────
  static const int maxDesignElements = 50;
  static const int maxUndoHistory = 30;
  static const double designCanvasWidth = 400.0;
  static const double designCanvasHeight = 500.0;
  static const List<String> supportedFonts = [
    'Outfit',
    'Poppins',
    'Montserrat',
    'Bebas Neue',
    'Pacifico',
    'Anton',
  ];
  static const List<String> baseProductColors = [
    '0xFFFFFFFF', // White
    '0xFF000000', // Black
    '0xFF1565C0', // Navy
    '0xFFC62828', // Red
    '0xFF2E7D32', // Forest Green
    '0xFFE65100', // Orange
    '0xFF6A1B9A', // Purple
    '0xFF37474F', // Charcoal
    '0xFFF9A825', // Yellow
    '0xFF00695C', // Teal
  ];

  // ── Orders ────────────────────────────────────────────────────────────────
  static const List<String> orderStatuses = [
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'out_for_delivery',
    'delivered',
    'cancelled',
    'refunded',
  ];

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int featuredProductLimit = 10;
  static const int searchResultsLimit = 50;

  // ── Animation durations ───────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration bannerAutoScrollInterval = Duration(seconds: 4);

  // ── Cache / storage keys ──────────────────────────────────────────────────
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyAuthToken = 'auth_token';
  static const String prefKeyUser = 'cached_user';
  static const String prefKeySavedDesigns = 'saved_designs';
  static const String prefKeyCartItems = 'cart_items';
  static const String prefKeyOnboardingSeen = 'onboarding_seen';
  static const String prefKeySelectedLanguage = 'selected_language';
  static const String prefKeySelectedCurrency = 'selected_currency';
  static const String prefKeyPushNotifications = 'push_notifications';
  static const String prefKeyOrderNotifications = 'order_notifications';
  static const String prefKeyPromoNotifications = 'promo_notifications';

  // ── Currency / locale ─────────────────────────────────────────────────────
  static const String defaultCurrency = 'INR';
  static const String defaultCurrencySymbol = '₹';
  static const String defaultLocale = 'en_IN';
  static const List<Map<String, String>> supportedCurrencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  ];
}
