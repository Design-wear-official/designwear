import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

/// The menu on the profile icon in the home header: new design, search,
/// notifications, cart, profile and settings.
///
/// It opens when the mouse hovers over the icon and stays open while the mouse
/// is on the icon or the menu. Touch screens have no hover, so a tap on the icon
/// opens (and closes) it too.
class HomeProfileMenu extends StatefulWidget {
  const HomeProfileMenu({
    super.key,
    required this.builder,
    required this.onSearch,
  });

  /// Draws the icon. Call the second argument when the icon is tapped.
  final Widget Function(BuildContext context, VoidCallback toggle) builder;

  /// Opens the search page.
  final VoidCallback onSearch;

  @override
  State<HomeProfileMenu> createState() => _HomeProfileMenuState();
}

class _HomeProfileMenuState extends State<HomeProfileMenu> {
  final _controller = MenuController();
  Timer? _closeTimer;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _show() {
    _closeTimer?.cancel();
    if (!_controller.isOpen) _controller.open();
  }

  // A short delay lets the mouse cross the gap between the icon and the menu.
  void _hideSoon() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 250), () {
      if (_controller.isOpen) _controller.close();
    });
  }

  void _toggle() => _controller.isOpen ? _controller.close() : _show();

  void _go(String name, Widget page) {
    _controller.close();
    Navigator.of(context).push(
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
    final name = auth.user?.name.trim() ?? '';

    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(0, 6),
      style: const MenuStyle(alignment: AlignmentDirectional.bottomEnd),
      menuChildren: [
        MouseRegion(
          onEnter: (_) => _closeTimer?.cancel(),
          onExit: (_) => _hideSoon(),
          child: SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (auth.isSignedIn)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (name.isNotEmpty)
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        Text(
                          auth.user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: context.muted),
                        ),
                      ],
                    ),
                  ),
                _Item(
                  icon: Icons.add_circle_outline,
                  label: 'New design',
                  onTap: () =>
                      _go('/design-studio', const DesignStudioScreen()),
                ),
                _Item(
                  icon: Icons.search,
                  label: 'Search designs',
                  onTap: () {
                    _controller.close();
                    widget.onSearch();
                  },
                ),
                const Divider(height: 8),
                if (showInbox)
                  _Item(
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    badge: unread > 0 ? '$unread' : null,
                    onTap: () =>
                        _go('/notifications', const NotificationsScreen()),
                  ),
                _Item(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Cart',
                  badge: cart.count > 0 ? '${cart.count}' : null,
                  onTap: () => _go('/cart', const CartScreen()),
                ),
                _Item(
                  icon: Icons.person_outline,
                  label: auth.isSignedIn ? 'Profile' : 'Sign in',
                  onTap: () => auth.isSignedIn
                      ? _go('/profile', const ProfileScreen())
                      : _go('/login', const LoginScreen()),
                ),
                _Item(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => _go('/settings', const SettingsScreen()),
                ),
              ],
            ),
          ),
        ),
      ],
      child: MouseRegion(
        onEnter: (_) => _show(),
        onExit: (_) => _hideSoon(),
        child: widget.builder(context, _toggle),
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
      dense: true,
      leading: Icon(icon, color: context.ink),
      title: Text(label),
      trailing: badge == null
          ? null
          : Badge(label: Text(badge!), backgroundColor: context.accent),
      onTap: onTap,
    );
  }
}
