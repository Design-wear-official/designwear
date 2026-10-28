import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth/auth_service.dart';
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
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          if (user == null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    size: 64,
                    color: context.muted,
                  ),
                  const SizedBox(height: 12),
                  const Text('Sign in to place orders and save designs'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _open(context, const LoginScreen()),
                    child: const Text('Sign in'),
                  ),
                  TextButton(
                    onPressed: () => _open(context, const RegisterScreen()),
                    child: const Text('Create account'),
                  ),
                ],
              ),
            )
          else
            ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.purple,
                child: Text(
                  user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                ),
              ),
              title: Text(
                user.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(
                user.phone.isEmpty
                    ? user.email
                    : '${user.email}\n${user.phone}',
              ),
              trailing: IconButton(
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(context, auth),
              ),
            ),
          const Divider(),
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('My orders'),
              onTap: () => _open(context, const MyOrdersScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Shipping addresses'),
              onTap: () => _open(context, const AddressesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Payment methods'),
              onTap: () => _open(context, const PaymentMethodsScreen()),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Community designs'),
            onTap: () => _open(context, const CommunityScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Saved designs'),
            onTap: () => _open(context, const SavedDesignsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () => _open(context, const SettingsScreen()),
          ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: auth.signOut,
            ),
        ],
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
