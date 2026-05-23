import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../config/app_constants.dart';
import '../presentation/utils/responsive_utils.dart';
import '../presentation/styles/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification preferences (in a real app these come from SharedPreferences)
  bool _orderNotifications = true;
  bool _promoNotifications = true;
  bool _designNotifications = false;
  bool _pushNotifications = true;

  // Language / currency (demo state)
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'INR (₹)';

  static const List<String> _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Bengali',
  ];

  static const List<String> _currencies = [
    'INR (₹)',
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: ResponsiveSizes.pagePadding(context),
            children: [
              // ── Appearance ────────────────────────────────────────────────
              _SectionHeader(title: 'Appearance'),
              _SettingsCard(
                isDark: isDark,
                children: [
                  _ThemeTile(themeProvider: themeProvider),
                ],
              ),

              const SizedBox(height: 20),

              // ── Notifications ─────────────────────────────────────────────
              _SectionHeader(title: 'Notifications'),
              _SettingsCard(
                isDark: isDark,
                children: [
                  _SwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Enable all notifications',
                    value: _pushNotifications,
                    onChanged: (v) => setState(() {
                      _pushNotifications = v;
                      if (!v) {
                        _orderNotifications = false;
                        _promoNotifications = false;
                        _designNotifications = false;
                      }
                    }),
                  ),
                  _Divider(),
                  _SwitchTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Order Updates',
                    subtitle: 'Shipping, delivery, and status changes',
                    value: _orderNotifications && _pushNotifications,
                    enabled: _pushNotifications,
                    onChanged: (v) => setState(() => _orderNotifications = v),
                  ),
                  _Divider(),
                  _SwitchTile(
                    icon: Icons.local_offer_outlined,
                    title: 'Promotions & Offers',
                    subtitle: 'Deals, discounts, and new arrivals',
                    value: _promoNotifications && _pushNotifications,
                    enabled: _pushNotifications,
                    onChanged: (v) => setState(() => _promoNotifications = v),
                  ),
                  _Divider(),
                  _SwitchTile(
                    icon: Icons.palette_outlined,
                    title: 'Design Reminders',
                    subtitle: 'Unsaved designs and new templates',
                    value: _designNotifications && _pushNotifications,
                    enabled: _pushNotifications,
                    onChanged: (v) => setState(() => _designNotifications = v),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Language & Region ─────────────────────────────────────────
              _SectionHeader(title: 'Language & Region'),
              _SettingsCard(
                isDark: isDark,
                children: [
                  _DropdownTile(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    value: _selectedLanguage,
                    items: _languages,
                    onChanged: (v) => setState(() => _selectedLanguage = v!),
                  ),
                  _Divider(),
                  _DropdownTile(
                    icon: Icons.currency_rupee_outlined,
                    title: 'Currency',
                    value: _selectedCurrency,
                    items: _currencies,
                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Account ───────────────────────────────────────────────────
              _SectionHeader(title: 'Account'),
              _SettingsCard(
                isDark: isDark,
                children: [
                  _NavTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your login credentials',
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  _Divider(),
                  _NavTile(
                    icon: Icons.security_outlined,
                    title: 'Two-Factor Authentication',
                    subtitle: 'Add an extra layer of security',
                    onTap: () => _showComingSoon(context, 'Two-Factor Auth'),
                  ),
                  _Divider(),
                  _NavTile(
                    icon: Icons.download_outlined,
                    title: 'Download My Data',
                    subtitle: 'Export your account data',
                    onTap: () => _showComingSoon(context, 'Data Export'),
                  ),
                  _Divider(),
                  _NavTile(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove your account',
                    titleColor: colorScheme.error,
                    iconColor: colorScheme.error,
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── About ─────────────────────────────────────────────────────
              _SectionHeader(title: 'About'),
              _SettingsCard(
                isDark: isDark,
                children: [
                  _NavTile(
                    icon: Icons.info_outline,
                    title: 'Terms of Service',
                    onTap: () => _showComingSoon(context, 'Terms of Service'),
                  ),
                  _Divider(),
                  _NavTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _showComingSoon(context, 'Privacy Policy'),
                  ),
                  _Divider(),
                  _NavTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: AppConstants.supportEmail,
                    onTap: () => _showComingSoon(context, 'Help & Support'),
                  ),
                  _Divider(),
                  _NavTile(
                    icon: Icons.star_outline,
                    title: 'Rate the App',
                    subtitle: 'Share your feedback on the store',
                    onTap: () => _showComingSoon(context, 'Rate App'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Version info ──────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      AppConstants.appDisplayName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version ${AppConstants.appVersion} (${AppConstants.appBuildNumber})',
                      style: GoogleFonts.outfit(
                        color: colorScheme.onSurface.withOpacity(0.35),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Password', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PasswordField(controller: currentPwCtrl, label: 'Current Password'),
            const SizedBox(height: 12),
            _PasswordField(controller: newPwCtrl, label: 'New Password'),
            const SizedBox(height: 12),
            _PasswordField(controller: confirmPwCtrl, label: 'Confirm New Password'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Theme.of(ctx).hintColor)),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPwCtrl.text != confirmPwCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully')),
              );
            },
            child: Text('Update', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Account?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Theme.of(ctx).colorScheme.error,
          ),
        ),
        content: Text(
          'This action is permanent and cannot be undone. All your data, orders, and designs will be deleted.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showComingSoon(context, 'Account Deletion');
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!', style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Local widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, top: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: AppColors.borderLight)
            : Border.all(color: colorScheme.outline.withOpacity(0.12)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = enabled ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.3);

    return SwitchListTile(
      secondary: Icon(icon, color: effectiveColor, size: 22),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.4),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Theme.of(context).hintColor.withOpacity(enabled ? 1 : 0.5),
              ),
            )
          : null,
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? colorScheme.primary, size: 22),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w500,
          color: titleColor ?? colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).hintColor),
            )
          : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).hintColor),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary, size: 22),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
        items: items
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: onChanged,
        dropdownColor: colorScheme.surface,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final ThemeProvider themeProvider;
  const _ThemeTile({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final modes = [
      (ThemeMode.system, Icons.brightness_auto, 'System'),
      (ThemeMode.light, Icons.light_mode_outlined, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: colorScheme.primary, size: 22),
              const SizedBox(width: 12),
              Text(
                'Theme',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: modes.map((entry) {
              final (mode, icon, label) = entry;
              final isSelected = themeProvider.themeMode == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => themeProvider.setThemeMode(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  const _PasswordField({required this.controller, required this.label});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
