/// One message in the in-app inbox (an order update).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    required this.read,
    this.orderId,
  });

  final String id, title, body;
  final DateTime at;
  final bool read;
  final String? orderId;

  factory AppNotification.fromApi(Map<String, Object?> j) => AppNotification(
    id: '${j['id']}',
    title: '${j['title']}',
    body: '${j['body']}',
    at: DateTime.parse('${j['at']}'),
    read: j['read'] == true,
    orderId: (j['orderId'] as String?)?.isEmpty ?? true
        ? null
        : j['orderId'] as String?,
  );
}
