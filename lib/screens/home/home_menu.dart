import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/widgets/designwear_logo.dart';
import '../../services/auth/auth_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/shop/cart_service.dart';
import '../../theme/app_theme.dart' show AppThemeColors;
import '../account/auth_screens.dart' show LoginScreen;
import '../account/profile_screen.dart';
import '../cart/cart_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../studio/editor/design_studio_screen.dart';

/// The hamburger menu on the home page: new design, search, notifications,
/// cart, profile and settings. Each entry closes the menu and opens its page.
class HomeMenuDrawer extends StatelessWidget {
  const HomeMenuDrawer({super.key, required this.onSearch});

  /// Opens the search page.
  final VoidCallback onSearch;

  void _open(BuildContext context, String name, Widget page) {
    // Close the menu first, then open the page over the home page.
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(name: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final cart = context.watch<CartService>();
    final inbox = context.watch<NotificationService?>();
    final unread = inbox?.unread ?? 0;
    final showInbox = auth.isSignedIn && auth.isRemote;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DesignWearLogo(size: 44),
              ),
            ),
            _Item(
              icon: Icons.add_circle_outline,
              label: 'New design',
              onTap: () =>
                  _open(context, '/design-studio', const DesignStudioScreen()),
            ),
            _Item(
              icon: Icons.search,
              label: 'Search designs',
              onTap: () {
                Navigator.of(context).pop();
                onSearch();
              },
            ),
            const Divider(),
            if (showInbox)
              _Item(
                icon: Icons.notifications_none,
                label: 'Notifications',
                badge: unread > 0 ? '$unread' : null,
                onTap: () => _open(
                  context,
                  '/notifications',
                  const NotificationsScreen(),
                ),
              ),
            _Item(
              icon: Icons.shopping_bag_outlined,
              label: 'Cart',
              badge: cart.count > 0 ? '${cart.count}' : null,
              onTap: () => _open(context, '/cart', const CartScreen()),
            ),
            _Item(
              icon: Icons.person_outline,
              label: auth.isSignedIn ? 'Profile' : 'Sign in',
              onTap: () => auth.isSignedIn
                  ? _open(context, '/profile', const ProfileScreen())
                  : _open(context, '/login', const LoginScreen()),
            ),
            _Item(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => _open(context, '/settings', const SettingsScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.ink),
      title: Text(label),
      trailing: badge == null
          ? null
          : Badge(label: Text(badge!), backgroundColor: context.accent),
      onTap: onTap,
    );
  }
}
