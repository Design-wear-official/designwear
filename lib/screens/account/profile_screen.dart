import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/commerce.dart';
import '../../presentation/widgets/content_width.dart';
import '../../presentation/widgets/settings_group.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../services/ai/ai_usage_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/shop/stores.dart';
import '../../theme/app_theme.dart';
import 'addresses_screen.dart';
import 'auth_screens.dart';
import '../orders/my_orders_screen.dart';
import 'payment_methods_screen.dart';
import '../studio/community/community_screen.dart';
import '../studio/library/saved_designs_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final inbox = context.watch<NotificationService>();
    final orders = context.watch<OrderStore>();
    final user = auth.user;
    final active = orders.items
        .where(
          (o) =>
              o.status != OrderStatus.delivered &&
              o.status != OrderStatus.cancelled,
        )
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ContentWidth(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (user == null)
              _SignedOutCard(
                onSignIn: () => _open(context, const LoginScreen()),
                onRegister: () => _open(context, const RegisterScreen()),
              )
            else
              _ProfileHeader(user: user, onEdit: () => _edit(context, auth)),
            const SizedBox(height: 20),
            if (user != null && (maybeAiUsage(context)?.known ?? false))
              SettingsGroup(
                title: 'Plan',
                children: [
                  SettingsRow(
                    icon: Icons.auto_awesome,
                    title: '${maybeAiUsage(context)!.planLabel} plan',
                    subtitle: maybeAiUsage(context)!.summary,
                    onTap: null,
                  ),
                ],
              ),
            if (user != null && (maybeAiUsage(context)?.known ?? false))
              const SizedBox(height: 20),
            if (user != null)
              SettingsGroup(
                title: 'Shopping',
                children: [
                  SettingsRow(
                    icon: Icons.receipt_long_outlined,
                    title: 'My orders',
                    subtitle: active > 0 ? '$active in progress' : null,
                    onTap: () => _open(context, const MyOrdersScreen()),
                  ),
                  if (auth.isRemote)
                    SettingsRow(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      badge: inbox.unread,
                      onTap: () => _open(context, const NotificationsScreen()),
                    ),
                  SettingsRow(
                    icon: Icons.location_on_outlined,
                    title: 'Shipping addresses',
                    onTap: () => _open(context, const AddressesScreen()),
                  ),
                  SettingsRow(
                    icon: Icons.payments_outlined,
                    title: 'Payment methods',
                    onTap: () => _open(context, const PaymentMethodsScreen()),
                  ),
                ],
              ),
            SettingsGroup(
              title: 'Designs',
              children: [
                SettingsRow(
                  icon: Icons.groups_outlined,
                  title: 'Community designs',
                  onTap: () => _open(context, const CommunityScreen()),
                ),
                SettingsRow(
                  icon: Icons.palette_outlined,
                  title: 'Saved designs',
                  onTap: () => _open(context, const SavedDesignsScreen()),
                ),
              ],
            ),
            SettingsGroup(
              title: 'App',
              children: [
                SettingsRow(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => _open(context, const SettingsScreen()),
                ),
              ],
            ),
            if (user != null)
              SettingsGroup(
                children: [
                  SettingsRow(
                    icon: Icons.logout,
                    title: 'Sign out',
                    danger: true,
                    onTap: auth.signOut,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, AuthService auth) async {
    final name = TextEditingController(text: auth.user!.name);
    final phone = TextEditingController(text: auth.user!.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await auth.updateProfile(
        name: name.text.trim(),
        phone: phone.text.trim(),
      );
    }
    name.dispose();
    phone.dispose();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onEdit});
  final UserProfile user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.purple,
            child: Text(
              user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.muted),
                ),
                if (user.phone.isNotEmpty)
                  Text(user.phone, style: TextStyle(color: context.muted)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutCard extends StatelessWidget {
  const _SignedOutCard({required this.onSignIn, required this.onRegister});
  final VoidCallback onSignIn;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(Icons.account_circle_outlined, size: 64, color: context.muted),
          const SizedBox(height: 12),
          const Text(
            'Sign in to place orders and save designs',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSignIn,
              child: const Text('Sign in'),
            ),
          ),
          TextButton(
            onPressed: onRegister,
            child: const Text('Create account'),
          ),
        ],
      ),
    );
  }
}
