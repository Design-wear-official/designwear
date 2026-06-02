import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'my_orders_screen.dart';
import 'saved_designs_screen.dart';
import 'shipping_addresses_screen.dart';
import 'payment_methods_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _pickImage(AuthService authService) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await authService.updateProfileImage(image.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          if (user == null) {
            return _NotLoggedIn(onLogin: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            });
          }

          return CustomScrollView(
            slivers: [
              // Collapsible app bar with gradient header
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: _ProfileHeader(
                    user: user,
                    isDark: isDark,
                    onEditPhoto: () => _pickImage(authService),
                    onEditProfile: () => _showEditProfileDialog(context, authService),
                  ),
                  collapseMode: CollapseMode.pin,
                ),
                title: Text(
                  user.name ?? 'Profile',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: ResponsiveSizes.pagePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Stats row
                      _StatsRow(isDark: isDark),
                      const SizedBox(height: 24),

                      // Menu sections
                      _MenuSection(
                        isDark: isDark,
                        title: 'Orders & Shopping',
                        items: [
                          _MenuItem(
                            icon: Icons.shopping_bag_outlined,
                            iconColor: const Color(0xFF4CAF50),
                            title: 'My Orders',
                            subtitle: 'Track and view order history',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
                          ),
                          _MenuItem(
                            icon: Icons.palette_outlined,
                            iconColor: AppColors.purple,
                            title: 'Saved Designs',
                            subtitle: 'Your custom creations',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedDesignsScreen())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _MenuSection(
                        isDark: isDark,
                        title: 'Account',
                        items: [
                          _MenuItem(
                            icon: Icons.location_on_outlined,
                            iconColor: const Color(0xFF2196F3),
                            title: 'Shipping Addresses',
                            subtitle: 'Manage delivery locations',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShippingAddressesScreen())),
                          ),
                          _MenuItem(
                            icon: Icons.credit_card_outlined,
                            iconColor: const Color(0xFFFF9800),
                            title: 'Payment Methods',
                            subtitle: 'Manage saved cards & UPI',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
                          ),
                          _MenuItem(
                            icon: Icons.settings_outlined,
                            iconColor: colorScheme.onSurface.withOpacity(0.6),
                            title: 'Settings',
                            subtitle: 'Theme, notifications & more',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _MenuSection(
                        isDark: isDark,
                        title: 'Support',
                        items: [
                          _MenuItem(
                            icon: Icons.help_outline,
                            iconColor: const Color(0xFF00BCD4),
                            title: 'Help & Support',
                            subtitle: 'FAQs and contact us',
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.share_outlined,
                            iconColor: const Color(0xFF4CAF50),
                            title: 'Refer a Friend',
                            subtitle: 'Earn rewards for referrals',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'EARN ₹50',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF9800),
                                ),
                              ),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Logout
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context, authService),
                          icon: const Icon(Icons.logout, size: 18),
                          label: Text(
                            'Log Out',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error.withOpacity(0.6)),
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveSizes.buttonPaddingVertical(context),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Out?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              authService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text('Log Out', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthService authService) {
    final nameController = TextEditingController(text: authService.currentUser?.name);
    final emailController = TextEditingController(text: authService.currentUser?.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Theme.of(ctx).hintColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await authService.updateProfile(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated!')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: Text('Save', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  final VoidCallback onEditPhoto;
  final VoidCallback onEditProfile;

  const _ProfileHeader({
    required this.user,
    required this.isDark,
    required this.onEditPhoto,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [colorScheme.primary.withOpacity(0.08), colorScheme.secondary.withOpacity(0.05)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  GestureDetector(
                    onTap: onEditPhoto,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.primary.withOpacity(0.2),
                      backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? (user.photoUrl!.startsWith('http')
                              ? NetworkImage(user.photoUrl!) as ImageProvider
                              : FileImage(File(user.photoUrl!)))
                          : null,
                      child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                          ? Text(
                              _initials(user.name),
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onEditPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.surface, width: 2),
                        ),
                        child: Icon(Icons.camera_alt, size: 12, color: colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Name & email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.name ?? 'User',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (user.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email!,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (user.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '+91 ${user.phone}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Edit button
              IconButton(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit profile',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return parts.first[0].toUpperCase();
  }
}

class _StatsRow extends StatelessWidget {
  final bool isDark;
  const _StatsRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: '0', label: 'Orders', icon: Icons.shopping_bag_outlined, isDark: isDark),
        const SizedBox(width: 12),
        _StatCard(value: '0', label: 'Designs', icon: Icons.palette_outlined, isDark: isDark),
        const SizedBox(width: 12),
        _StatCard(value: '0', label: 'Points', icon: Icons.stars_outlined, isDark: isDark),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isDark;
  const _StatCard({required this.value, required this.label, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  final bool isDark;
  const _MenuSection({required this.title, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
            boxShadow: isDark
                ? null
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _MenuItemTile(item: item),
                  if (i < items.length - 1)
                    Divider(height: 1, indent: 56, color: colorScheme.outline.withOpacity(0.12)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });
}

class _MenuItemTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: item.onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: item.iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon, color: item.iconColor, size: 20),
      ),
      title: Text(
        item.title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).hintColor),
            )
          : null,
      trailing: item.trailing ??
          Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.onSurface.withOpacity(0.3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  final VoidCallback onLogin;
  const _NotLoggedIn({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle_outlined, size: 80, color: colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 20),
            Text(
              'You\'re not logged in',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Log in to view your orders, designs, and saved addresses.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Log In', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
