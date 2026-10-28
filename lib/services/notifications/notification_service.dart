import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';
import '../../logging/app_log.dart';
import '../../models/app_notification.dart';

/// The signed-in person's inbox, from the API. Errors leave the list as it was.
class NotificationService extends ChangeNotifier {
  NotificationService({this.api});
  final ApiClient? api;

  List<AppNotification> _items = const [];
  List<AppNotification> get items => _items;
  int get unread => _items.where((n) => !n.read).length;

  Future<void> refresh() async {
    if (api == null || !api!.hasToken) return;
    try {
      final j = await api!.get('/v1/notifications');
      _items = [
        for (final e in (j['items'] as List? ?? const []))
          AppNotification.fromApi((e as Map).cast()),
      ];
      notifyListeners();
    } catch (e) {
      AppLog.instance.warning('notifications', 'Could not load the inbox', e);
    }
  }

  Future<void> markAllRead() async {
    if (api == null || unread == 0) return;
    _items = [
      for (final n in _items)
        AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          at: n.at,
          read: true,
          orderId: n.orderId,
        ),
    ];
    notifyListeners();
    try {
      await api!.post('/v1/notifications/read');
    } catch (e) {
      AppLog.instance.warning('notifications', 'Could not mark as read', e);
    }
  }

  /// Signing out: the next person must not see this inbox.
  void clear() {
    _items = const [];
    notifyListeners();
  }
}
