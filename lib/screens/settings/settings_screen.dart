import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cms/cms_service.dart';
import '../../flavours/flavour_selector.dart';
import '../../presentation/widgets/designwear_logo.dart';
import '../../services/shop/cart_service.dart';
import '../../services/shop/stores.dart';
import '../../services/app/theme_service.dart';
import 'diagnostics_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final cms = CmsService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Appearance'),
          ),
          RadioGroup<ThemeMode>(
            groupValue: theme.mode,
            onChanged: (m) => m == null ? null : theme.set(m),
            child: const Column(
              children: [
                RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
                RadioListTile(value: ThemeMode.light, title: Text('Light')),
                RadioListTile(
                  value: ThemeMode.system,
                  title: Text('Match system'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Catalog connection'),
            subtitle: Text(cms == null ? 'Not configured' : cms.config.baseUrl),
            trailing: cms == null
                ? null
                : FutureBuilder<bool>(
                    future: cms.isHealthy(),
                    builder: (_, s) => Icon(
                      s.data == true ? Icons.check_circle : Icons.error_outline,
                      color: s.data == true ? Colors.green : Colors.grey,
                    ),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Diagnostics'),
            subtitle: const Text('View the log and choose what is reported'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Clear cart and orders on this device'),
            onTap: () async {
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
              if (ok == true && context.mounted) {
                context.read<CartService>().clear();
                await context.read<OrderStore>().clear();
              }
            },
          ),
          AboutListTile(
            icon: const Icon(Icons.info_outline),
            applicationIcon: const DesignWearLogo(size: 48),
            applicationName: getAppTitle(),
            applicationVersion: '1.0.0 ($flavour)',
          ),
        ],
      ),
    );
  }
}
