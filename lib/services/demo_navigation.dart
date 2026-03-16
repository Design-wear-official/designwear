import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../config/demo_config.dart';

/// Enhanced navigation service with demo-friendly transitions and helpers
class DemoNavigation {
  static final DemoNavigation _instance = DemoNavigation._internal();
  factory DemoNavigation() => _instance;
  DemoNavigation._internal();

  /// Navigate with demo-aware transition
  static Future<T?> pushWithTransition<T>(
    BuildContext context,
    Widget page, {
    String? routeName,
    bool fullscreenDialog = false,
  }) async {
    if (DemoConfig().isDemoMode) {
      DemoConfig().trackDemoAction('navigate', properties: {
        'route': routeName ?? page.runtimeType.toString(),
        'from': ModalRoute.of(context)?.settings.name ?? 'unknown',
      });
    }

    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        fullscreenDialog: fullscreenDialog,
        settings: RouteSettings(name: routeName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth slide transition
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                CurveTween(curve: Curves.easeInOutCubic),
              ),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Navigate with fade transition (good for modal-like screens)
  static Future<T?> pushWithFade<T>(
    BuildContext context,
    Widget page, {
    String? routeName,
  }) async {
    if (DemoConfig().isDemoMode) {
      DemoConfig().trackDemoAction('navigate_fade', properties: {
        'route': routeName ?? page.runtimeType.toString(),
      });
    }

    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        settings: RouteSettings(name: routeName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  /// Navigate with scale transition (good for action buttons)
  static Future<T?> pushWithScale<T>(
    BuildContext context,
    Widget page, {
    String? routeName,
  }) async {
    if (DemoConfig().isDemoMode) {
      DemoConfig().trackDemoAction('navigate_scale', properties: {
        'route': routeName ?? page.runtimeType.toString(),
      });
    }

    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        settings: RouteSettings(name: routeName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: animation.drive(
              CurveTween(curve: Curves.easeInOutCubic),
            ),    
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Show demo-friendly modal bottom sheet
  static Future<T?> showDemoBottomSheet<T>(
    BuildContext context, {
    required Widget Function(BuildContext) builder,
    String? title,
    bool isScrollControlled = false,
    bool enableDrag = true,
  }) async {
    if (DemoConfig().isDemoMode) {
      DemoConfig().trackDemoAction('show_bottom_sheet', properties: {
        'title': title,
        'scrollControlled': isScrollControlled,
      });
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title if provided
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Content
            Flexible(child: builder(context)),
          ],
        ),
      ),
    );
  }

  /// Show demo-friendly snackbar with enhanced styling
  static void showDemoSnackBar(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    SnackBarType type = SnackBarType.info,
  }) {
    if (DemoConfig().isDemoMode) {
      DemoConfig().trackDemoAction('show_snackbar', properties: {
        'message': message.length > 50 ? '${message.substring(0, 50)}...' : message,
        'type': type.name,
        'has_action': actionLabel != null,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getSnackBarIcon(type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getSnackBarColor(type),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Navigate to login with auth-aware logic
  static Future<void> navigateToLogin(BuildContext context) async {
    final authService = context.read<AuthService>();
    
    if (DemoConfig().isDemoMode) {
      // In demo mode, show a demo login experience
      showDemoSnackBar(
        context,
        '🎭 Demo Mode: Login simulation activated!',
        actionLabel: 'Try Demo',
        onAction: () {
          authService.loginAsGuest(); // Demo login
        },
        type: SnackBarType.info,
      );
    }
    
    // Navigate to actual login screen
    // pushWithTransition(context, const LoginScreen(), routeName: '/login');
  }

  /// Smart back navigation that handles demo state
  static void smartPop(BuildContext context, [dynamic result]) {
    if (DemoConfig().isDemoMode) {
      DemoConfig().trackDemoAction('navigate_back', properties: {
        'can_pop': Navigator.canPop(context),
        'has_result': result != null,
      });
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    } else {
      // Handle root navigation in demo mode
      showDemoSnackBar(
        context,
        'Already at home screen',
        type: SnackBarType.info,
      );
    }
  }

  static IconData _getSnackBarIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle;
      case SnackBarType.error:
        return Icons.error;
      case SnackBarType.warning:
        return Icons.warning;
      case SnackBarType.info:
        return Icons.info;
    }
  }

  static Color _getSnackBarColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Colors.green;
      case SnackBarType.error:
        return Colors.red;
      case SnackBarType.warning:
        return Colors.orange;
      case SnackBarType.info:
        return Colors.blue;
    }
  }
}

enum SnackBarType {
  success,
  error,
  warning,
  info,
}