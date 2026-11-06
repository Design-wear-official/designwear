/// A customer's request to return a delivered order, as the API reports it.
enum ReturnStatus { requested, approved, rejected, refunded }

class ReturnRequest {
  const ReturnRequest({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.note,
  });

  final String id, orderId, reason;
  final double amount;
  final ReturnStatus status;
  final DateTime createdAt;

  /// What the desk wrote when it decided (for example why it was rejected).
  final String? note;

  String get label => switch (status) {
    ReturnStatus.requested => 'Return requested',
    ReturnStatus.approved => 'Return approved, refund on its way',
    ReturnStatus.rejected => 'Return declined',
    ReturnStatus.refunded => 'Refunded',
  };

  /// A declined return may be asked for again.
  bool get isOpen =>
      status == ReturnStatus.requested ||
      status == ReturnStatus.approved ||
      status == ReturnStatus.refunded;

  factory ReturnRequest.fromApi(Map<String, Object?> j) {
    final history = (j['history'] as List? ?? const []).cast<Map>();
    final decision = history.lastWhere(
      (h) => h['note'] != null,
      orElse: () => const {},
    );
    return ReturnRequest(
      id: '${j['id']}',
      orderId: '${j['orderId']}',
      reason: '${j['reason'] ?? ''}',
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse('${j['createdAt']}'),
      note: decision['note'] as String?,
      status: switch ('${j['status']}') {
        'approved' => ReturnStatus.approved,
        'rejected' => ReturnStatus.rejected,
        'refunded' => ReturnStatus.refunded,
        _ => ReturnStatus.requested,
      },
    );
  }
}
