import 'package:flutter/foundation.dart';
import '../services/demo_data_service.dart';
import '../config/app_config.dart';

/// Demo configuration and setup helper
class DemoConfig {
  static final DemoConfig _instance = DemoConfig._internal();
  factory DemoConfig() => _instance;
  DemoConfig._internal();

  /// Check if the app is running in demo mode
  bool get isDemoMode {
    // Demo mode is enabled when:
    // 1. In debug mode, OR
    // 2. No API configuration is available, OR  
    // 3. Explicitly set to demo mode
    return kDebugMode || 
           SanityConfig.projectId.isEmpty || 
           !WebApiConfig.useWebApi ||
           AppConfig.dataSource == 'demo';
  }

  /// Initialize demo data and settings
  Future<void> initializeDemoMode() async {
    if (!isDemoMode) return;

    debugPrint('🎭 Demo Mode Active - Loading demo data and features');
    
    // Pre-load demo data to ensure it's available immediately
    final demoService = DemoDataService();
    debugPrint('📦 Loaded ${demoService.demoProducts.length} demo products');
    debugPrint('🏷️ Loaded ${demoService.demoCategories.length} demo categories');
    
    // Log demo features available
    debugPrint('🎨 Demo features enabled:');
    debugPrint('  • Welcome banners and tips');
    debugPrint('  • Demo products and categories');
    debugPrint('  • Design studio templates');
    debugPrint('  • Quick action buttons');
    debugPrint('  • Offline-first experience');
  }

  /// Get demo status message for display
  String get statusMessage {
    if (isDemoMode) {
      return 'Demo Mode: Explore all features with sample data';
    }
    return 'Live Mode: Connected to production services';
  }

  /// Get demo notification for users
  Map<String, dynamic>? get demoNotification {
    if (!isDemoMode) return null;
    
    return {
      'title': '🎭 Demo Mode Active',
      'message': 'You\'re exploring DesignWear with demo data. All features are available to try!',
      'type': 'info',
      'persistent': false,
    };
  }

  /// Demo analytics/tracking (for development purposes)
  void trackDemoAction(String action, {Map<String, dynamic>? properties}) {
    if (!isDemoMode || !kDebugMode) return;
    
    debugPrint('📊 Demo Action: $action');
    if (properties != null) {
      properties.forEach((key, value) {
        debugPrint('    $key: $value');
      });
    }
  }

  /// Reset demo state (useful for testing)
  void resetDemoState() {
    if (!isDemoMode) return;
    
    debugPrint('🔄 Resetting demo state...');
    // Could implement shared preferences cleanup here
    // Could reset any demo-specific caches
  }
}

/// Demo feature flags
class DemoFeatures {
  static const bool enableWelcomeBanner = true;
  static const bool enableQuickActions = true;
  static const bool enableDesignStudioTips = true;
  static const bool enableOfflineMode = true;
  static const bool enableDemoTemplates = true;
  static const bool showDemoNotifications = true;
  
  /// Check if a specific demo feature is enabled
  static bool isEnabled(String feature) {
    switch (feature) {
      case 'welcome_banner':
        return enableWelcomeBanner;
      case 'quick_actions':
        return enableQuickActions;
      case 'design_tips':
        return enableDesignStudioTips;
      case 'offline_mode':
        return enableOfflineMode;
      case 'demo_templates':
        return enableDemoTemplates;
      case 'demo_notifications':
        return showDemoNotifications;
      default:
        return false;
    }
  }
}