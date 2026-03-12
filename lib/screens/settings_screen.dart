import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(context, 'Preferences'),
              SwitchListTile(
                title: Text('Dark Mode', style: TextStyle(color: colorScheme.onSurface)),
                subtitle: Text('Toggle dark appearance', style: TextStyle(color: Theme.of(context).hintColor)),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                secondary: Icon(
                  themeProvider.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                  color: colorScheme.primary,
                ),
              ),
              const Divider(),
              _buildSectionHeader(context, 'Account'),
              ListTile(
                leading: Icon(Icons.lock_outline, color: colorScheme.primary),
                title: Text('Change Password', style: TextStyle(color: colorScheme.onSurface)),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).hintColor),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.notifications_none, color: colorScheme.primary),
                title: Text('Notifications', style: TextStyle(color: colorScheme.onSurface)),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).hintColor),
                onTap: () {},
              ),
              const Divider(),
              _buildSectionHeader(context, 'About'),
              ListTile(
                leading: Icon(Icons.info_outline, color: colorScheme.primary),
                title: Text('Terms of Service', style: TextStyle(color: colorScheme.onSurface)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined, color: colorScheme.primary),
                title: Text('Privacy Policy', style: TextStyle(color: colorScheme.onSurface)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.help_outline, color: colorScheme.primary),
                title: Text('Help & Support', style: TextStyle(color: colorScheme.onSurface)),
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
