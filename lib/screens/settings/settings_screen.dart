import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../flavours/flavour_selector.dart';
import '../../presentation/widgets/content_width.dart';
import '../../presentation/widgets/designwear_logo.dart';
import '../../presentation/widgets/settings_group.dart';
import '../../services/app/theme_service.dart';
import '../../services/shop/cart_service.dart';
import '../../services/shop/stores.dart';
import 'diagnostics_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final api = context.read<ApiClient?>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ContentWidth(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            SettingsGroup(
              title: 'Appearance',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Dark'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_outlined),
                          label: Text('Auto'),
                        ),
                      ],
                      selected: {theme.mode},
                      onSelectionChanged: (s) => theme.set(s.first),
                    ),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Connection',
              children: [_ConnectionRow(api: api)],
            ),
            SettingsGroup(
              title: 'Support',
              children: [
                SettingsRow(
                  icon: Icons.bug_report_outlined,
                  title: 'Diagnostics',
                  subtitle: 'View the log and choose what is reported',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DiagnosticsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Data on this device',
              children: [
                SettingsRow(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Clear cart and orders',
                  subtitle: 'Removes them from this device only',
                  danger: true,
                  onTap: () => _confirmClear(context),
                ),
              ],
            ),
            SettingsGroup(
              title: 'About',
              children: [
                SettingsRow(
                  icon: Icons.info_outline,
                  title: getAppTitle(),
                  subtitle: 'Version 1.0.0 ($flavour)',
                  trailing: const DesignWearLogo(size: 36),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationIcon: const DesignWearLogo(size: 48),
                    applicationName: getAppTitle(),
                    applicationVersion: '1.0.0 ($flavour)',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final cart = context.read<CartService>();
    final orders = context.read<OrderStore>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear local data?'),
        content: const Text(
          'This removes your cart and order history from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      cart.clear();
      await orders.clear();
    }
  }
}

/// Shows which server the app talks to and whether it answers. Only the host is
/// shown, never a full address.
class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({required this.api});
  final ApiClient? api;

  Future<bool> _ping() async {
    try {
      final j = await api!.get('/v1/health');
      return j['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (api == null) {
      return const SettingsRow(
        icon: Icons.cloud_off_outlined,
        title: 'Server',
        subtitle: 'Not connected. Orders and designs stay on this device.',
      );
    }
    return FutureBuilder<bool>(
      future: _ping(),
      builder: (_, s) => SettingsRow(
        icon: Icons.cloud_outlined,
        title: 'Server',
        subtitle: Uri.parse(api!.baseUrl).host,
        trailing: s.connectionState != ConnectionState.done
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    s.data == true ? Icons.check_circle : Icons.error_outline,
                    color: s.data == true ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(s.data == true ? 'Online' : 'Not reachable'),
                ],
              ),
      ),
    );
  }
}
