import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration loader that supports both .env and dart-defines
class ConfigLoader {
  static const Map<String, String> _dartDefines = {
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

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  static String? get(String key) {
    // 1. Try injected build variables first
    final injectedValue = _dartDefines[key];
    if (injectedValue != null && injectedValue.isNotEmpty) {
      return injectedValue;
    }

    // 2. Fall back to dotenv
    if (dotenv.isInitialized) {
      return dotenv.env[key];
    }
    return null;
  }
}

/// Sanity CMS Configuration
class SanityConfig {
  static String get projectId => ConfigLoader.get('SANITY_PROJECT_ID') ?? '';
  static String get dataset => ConfigLoader.get('SANITY_DATASET') ?? 'production';
}

/// Web API Configuration
class WebApiConfig {
  static String get baseUrl =>
      ConfigLoader.get('WEB_API_BASE_URL') ?? 'https://designwear-backend.vishwamai.com/api';

  static bool get useWebApi => ConfigLoader.get('USE_WEB_API') == 'true';

  static Duration get timeout => Duration(
    seconds: int.parse(ConfigLoader.get('API_TIMEOUT_SECONDS') ?? '30'),
  );
}

/// App Configuration
class AppConfig {
  static String get appName => ConfigLoader.get('APP_NAME') ?? 'Design Wear';
  static bool get isDebug => ConfigLoader.get('DEBUG_MODE') == 'true';
  static String get dataSource => ConfigLoader.get('DATA_SOURCE') ?? 'sanity';
  static bool get enableFallback => ConfigLoader.get('ENABLE_FALLBACK') == 'true';
}
