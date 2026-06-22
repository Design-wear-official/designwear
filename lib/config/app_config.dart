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
    'GEMINI_API_KEY': String.fromEnvironment('GEMINI_API_KEY'),
    'RAZORPAY_KEY_ID': String.fromEnvironment('RAZORPAY_KEY_ID'),
    // Firebase — all platforms
    'FIREBASE_PROJECT_ID': String.fromEnvironment('FIREBASE_PROJECT_ID'),
    'FIREBASE_API_KEY': String.fromEnvironment('FIREBASE_API_KEY'),
    'FIREBASE_APP_ID': String.fromEnvironment('FIREBASE_APP_ID'),
    'FIREBASE_MESSAGING_SENDER_ID': String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    'FIREBASE_STORAGE_BUCKET': String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    // Firebase — web / Windows
    'FIREBASE_WEB_API_KEY': String.fromEnvironment('FIREBASE_WEB_API_KEY'),
    'FIREBASE_WEB_APP_ID': String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    'FIREBASE_WINDOWS_APP_ID': String.fromEnvironment('FIREBASE_WINDOWS_APP_ID'),
    // Firebase — Android
    'FIREBASE_ANDROID_API_KEY': String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
    'FIREBASE_ANDROID_APP_ID': String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
    // Firebase — iOS / macOS
    'FIREBASE_IOS_API_KEY': String.fromEnvironment('FIREBASE_IOS_API_KEY'),
    'FIREBASE_IOS_APP_ID': String.fromEnvironment('FIREBASE_IOS_APP_ID'),
    'FIREBASE_IOS_BUNDLE_ID': String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
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
  // Project ID is public — visible in every CDN request URL.
  static String get projectId => ConfigLoader.get('SANITY_PROJECT_ID') ?? 'jh7llku7';
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
  static String get appName => ConfigLoader.get('APP_NAME') ?? 'DesignWear';
  static bool get isDebug => ConfigLoader.get('DEBUG_MODE') == 'true';
  static String get dataSource => ConfigLoader.get('DATA_SOURCE') ?? 'sanity';
  static bool get enableFallback => ConfigLoader.get('ENABLE_FALLBACK') == 'true';
}

/// Google Gemini AI Configuration
class GeminiConfig {
  static String get apiKey => ConfigLoader.get('GEMINI_API_KEY') ?? '';
  static bool get isConfigured => apiKey.isNotEmpty;
  static const String model = 'gemini-3.5-flash';
  static const int maxOutputTokens = 8192;
  static const double temperature = 0.7;
}

/// Razorpay Payment Configuration
class RazorpayConfig {
  static String get keyId => ConfigLoader.get('RAZORPAY_KEY_ID') ?? '';
  static bool get isConfigured => keyId.isNotEmpty;
  static const String currency = 'INR';
}

/// Firebase Configuration (runtime values, not the google-services.json ones)
class FirebaseRuntimeConfig {
  static String get projectId => ConfigLoader.get('FIREBASE_PROJECT_ID') ?? '';
  static String get apiKey => ConfigLoader.get('FIREBASE_API_KEY') ?? '';
  static String get appId => ConfigLoader.get('FIREBASE_APP_ID') ?? '';
  static String get messagingSenderId => ConfigLoader.get('FIREBASE_MESSAGING_SENDER_ID') ?? '';
  static String get storageBucket => ConfigLoader.get('FIREBASE_STORAGE_BUCKET') ?? '';
  static bool get isConfigured => projectId.isNotEmpty;
}
