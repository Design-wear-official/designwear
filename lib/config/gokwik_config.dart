import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration loader that supports both .env and env.json
class ConfigLoader {
  // Dart enforces compile-time constants for environment variable injection.
  static const Map<String, String> _dartDefines = {
    'GOKWIK_MERCHANT_ID': String.fromEnvironment('GOKWIK_MERCHANT_ID'),
    'GOKWIK_API_KEY': String.fromEnvironment('GOKWIK_API_KEY'),
    'GOKWIK_ENVIRONMENT': String.fromEnvironment('GOKWIK_ENVIRONMENT'),
    'SANITY_PROJECT_ID': String.fromEnvironment('SANITY_PROJECT_ID'),
    'SANITY_DATASET': String.fromEnvironment('SANITY_DATASET'),
    'APP_NAME': String.fromEnvironment('APP_NAME'),
    'DEBUG_MODE': String.fromEnvironment('DEBUG_MODE'),
    'DATA_SOURCE': String.fromEnvironment('DATA_SOURCE'),
    'ENABLE_FALLBACK': String.fromEnvironment('ENABLE_FALLBACK'),
    'WEB_API_BASE_URL': String.fromEnvironment('WEB_API_BASE_URL'),
    'API_TIMEOUT_SECONDS': String.fromEnvironment('API_TIMEOUT_SECONDS'),
    'USE_WEB_API': String.fromEnvironment('USE_WEB_API'),
  };

  static Map<String, dynamic>? _jsonConfig;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // We don't load env.json anymore due to security risks.
    // Web configs are injected via --dart-define.

    _initialized = true;
  }

  static String? get(String key) {
    // 1. Try injected build variables first (Best for Web & CI/CD)
    final injectedValue = _dartDefines[key];
    if (injectedValue != null && injectedValue.isNotEmpty) {
      return injectedValue;
    }

    // 2. Try JSON fallback if somehow populated
    if (_jsonConfig != null && _jsonConfig!.containsKey(key)) {
      return _jsonConfig![key]?.toString();
    }

    // 3. Fall back to dotenv (Used during local mobile development)
    if (dotenv.isInitialized) {
      return dotenv.env[key];
    }
    return null;
  }
}

/// GoKwik SDK Configuration
/// Reads values from env.json (web) or .env file (mobile)
class GoKwikConfig {
  /// Merchant ID provided by GoKwik
  static String get merchantId => ConfigLoader.get('GOKWIK_MERCHANT_ID') ?? '';

  /// API Key provided by GoKwik
  static String get apiKey => ConfigLoader.get('GOKWIK_API_KEY') ?? '';

  /// Environment: 'sandbox' for testing, 'production' for live
  static String get environment =>
      ConfigLoader.get('GOKWIK_ENVIRONMENT') ?? 'sandbox';

  /// Check if we're in sandbox mode
  static bool get isSandbox => environment == 'sandbox';

  /// Enable debug logging
  static bool get enableLogging => ConfigLoader.get('DEBUG_MODE') == 'true';
}

/// Sanity CMS Configuration
class SanityConfig {
  /// Sanity project ID
  static String get projectId => ConfigLoader.get('SANITY_PROJECT_ID') ?? '';

  /// Sanity dataset
  static String get dataset =>
      ConfigLoader.get('SANITY_DATASET') ?? 'production';
}

/// Web API Configuration
class WebApiConfig {
  /// Base URL for the Next.js web API
  static String get baseUrl =>
      ConfigLoader.get('WEB_API_BASE_URL') ?? 'http://localhost:3001/api';

  /// Whether to use web API instead of direct Sanity
  static bool get useWebApi => ConfigLoader.get('USE_WEB_API') == 'true';

  /// API timeout duration
  static Duration get timeout => Duration(
    seconds: int.parse(ConfigLoader.get('API_TIMEOUT_SECONDS') ?? '30'),
  );
}

/// App Configuration
class AppConfig {
  /// App name
  static String get appName => ConfigLoader.get('APP_NAME') ?? 'Design Wear';

  /// Debug mode
  static bool get isDebug => ConfigLoader.get('DEBUG_MODE') == 'true';

  /// Data source priority: 'web' for web API first, 'sanity' for Sanity first
  static String get dataSource => ConfigLoader.get('DATA_SOURCE') ?? 'sanity';

  /// Whether to fallback to alternative data source on failure
  static bool get enableFallback =>
      ConfigLoader.get('ENABLE_FALLBACK') == 'true';
}
