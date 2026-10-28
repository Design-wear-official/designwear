import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../presentation/widgets/content_width.dart';
import '../../services/notifications/notification_service.dart';
import '../../theme/app_theme.dart';
import '../orders/my_orders_screen.dart';

/// The inbox: order updates, newest first. Opening it marks everything as read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final inbox = context.read<NotificationService>();
    inbox.refresh().then((_) => inbox.markAllRead());
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<NotificationService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ContentWidth(
        child: RefreshIndicator(
          onRefresh: inbox.refresh,
          child: inbox.items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 160),
                    Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: context.muted,
                    ),
                    const SizedBox(height: 12),
                    const Center(child: Text('No notifications yet')),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Order updates will show up here.',
                        style: TextStyle(color: context.muted),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: inbox.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _Tile(item: inbox.items[i]),
                ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});
  final AppNotification item;

  static String _when(DateTime at) {
    final t = at.toLocal();
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      item.title.toLowerCase().contains('deliver')
          ? Icons.check_circle_outline
          : item.title.toLowerCase().contains('way')
          ? Icons.local_shipping_outlined
          : Icons.inventory_2_outlined,
      color: context.accent,
    ),
    title: Text(
      item.title,
      style: TextStyle(
        fontWeight: item.read ? FontWeight.w400 : FontWeight.w700,
      ),
    ),
    subtitle: Text(item.body),
    trailing: Text(
      _when(item.at),
      style: Theme.of(context).textTheme.bodySmall,
    ),
    onTap: item.orderId == null
        ? null
        : () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
  );
}
