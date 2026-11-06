import 'dart:convert';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    this.phone = '',
    this.staffRole,
  });
  final String name;
  final String email;
  final String phone;

  /// vendor, desk, delivery or owner when the owner made this account staff; otherwise null.
  final String? staffRole;
  bool get isStaff => staffRole != null;

  UserProfile copyWith({String? name, String? phone}) => UserProfile(
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    staffRole: staffRole,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    if (staffRole != null) 'staff': {'role': staffRole},
  };
  factory UserProfile.fromJson(Map<String, Object?> j) => UserProfile(
    name: '${j['name'] ?? ''}',
    email: '${j['email'] ?? ''}',
    phone: '${j['phone'] ?? ''}',
    staffRole: (j['staff'] as Map?)?['role'] as String?,
  );
}

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.line1,
    required this.city,
    required this.state,
    required this.pin,
  });
  final String id, label, name, phone, line1, city, state, pin;

  String get oneLine => '$line1, $city, $state $pin';

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'name': name,
    'phone': phone,
    'line1': line1,
    'city': city,
    'state': state,
    'pin': pin,
  };
  factory Address.fromJson(Map<String, Object?> j) => Address(
    id: '${j['id']}',
    label: '${j['label']}',
    name: '${j['name']}',
    phone: '${j['phone']}',
    line1: '${j['line1']}',
    city: '${j['city']}',
    state: '${j['state']}',
    pin: '${j['pin']}',
  );
}

enum PaymentKind { cod, upi, online }

/// Only non-sensitive payment info is stored: never card numbers.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.kind,
    required this.label,
  });
  final String id;
  final PaymentKind kind;
  final String label; // "Cash on delivery" or the UPI id

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'label': label,
  };
  factory PaymentMethod.fromJson(Map<String, Object?> j) => PaymentMethod(
    id: '${j['id']}',
    kind: PaymentKind.values.firstWhere(
      (k) => k.name == j['kind'],
      orElse: () => PaymentKind.cod,
    ),
    label: '${j['label']}',
  );
}

class CartLine {
  CartLine({
    required this.productId,
    required this.title,
    required this.unitPrice,
    required this.size,
    this.imageUrl,
    this.quantity = 1,
    this.designId,
  });

  final String productId;
  final String title;
  final double unitPrice;
  final String size;
  final String? imageUrl;
  final String? designId; // set for custom Studio designs
  int quantity;

  String get key => '$productId|$size|${designId ?? ''}';
  double get total => unitPrice * quantity;

  Map<String, Object?> toJson() => {
    'productId': productId,
    'title': title,
    'unitPrice': unitPrice,
    'size': size,
    'imageUrl': imageUrl,
    'quantity': quantity,
    'designId': designId,
  };
  factory CartLine.fromJson(Map<String, Object?> j) => CartLine(
    productId: '${j['productId']}',
    title: '${j['title']}',
    unitPrice: (j['unitPrice'] as num).toDouble(),
    size: '${j['size']}',
    imageUrl: j['imageUrl'] as String?,
    quantity: (j['quantity'] as num?)?.toInt() ?? 1,
    designId: j['designId'] as String?,
  );
}

enum OrderStatus {
  awaitingPayment,
  placed,
  confirmed,
  packed,
  processing,
  shipped,
  delivered,
  cancelled,
}

/// One step in an order's journey, as the server recorded it.
class OrderEvent {
  const OrderEvent({required this.status, required this.at, this.note});
  final String status;
  final DateTime at;
  final String? note;
}

/// Days after delivery a customer may ask to return an order (RETURN_WINDOW_DAYS on the server).
const returnWindowDays = 7;

class Order {
  const Order({
    required this.id,
    required this.createdAt,
    required this.lines,
    required this.address,
    required this.payment,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.status = OrderStatus.placed,
    this.teamName,
    this.history = const [],
    this.trackingId,
    this.carrier,
  });

  final String id;
  final DateTime createdAt;
  final List<CartLine> lines;
  final Address address;
  final PaymentMethod payment;
  final double subtotal, tax, total;
  final OrderStatus status;

  /// The local team that makes and delivers this order (server orders).
  final String? teamName;

  /// Each step the order has been through, oldest first (server orders).
  final List<OrderEvent> history;
  final String? trackingId, carrier;

  /// When the order was delivered (server orders), or null.
  DateTime? get deliveredAt {
    for (final e in history.reversed) {
      if (e.status == 'delivered') return e.at;
    }
    return null;
  }

  /// Whether a return can still be asked for. The server decides; this only
  /// decides whether to show the button.
  bool canReturn(DateTime now, {int windowDays = returnWindowDays}) {
    final at = deliveredAt;
    return status == OrderStatus.delivered &&
        at != null &&
        now.difference(at) <= Duration(days: windowDays);
  }

  Order copyWith({OrderStatus? status}) => Order(
    id: id,
    createdAt: createdAt,
    lines: lines,
    address: address,
    payment: payment,
    subtotal: subtotal,
    tax: tax,
    total: total,
    status: status ?? this.status,
    teamName: teamName,
    history: history,
    trackingId: trackingId,
    carrier: carrier,
  );

  /// Parses an order as returned by the DesignWear API (server-priced).
  factory Order.fromApi(Map<String, Object?> j) {
    final status = '${j['status']}';
    return Order(
      id: '${j['id']}',
      createdAt: DateTime.parse('${j['createdAt']}'),
      lines: (j['lines'] as List)
          .map((e) => CartLine.fromJson((e as Map).cast()))
          .toList(),
      address: Address.fromJson({
        'id': '',
        'label': '',
        ...((j['address'] as Map).cast<String, Object?>()),
      }),
      payment: ((j['payment'] as Map?)?['method'] == 'razorpay')
          ? const PaymentMethod(
              id: 'razorpay',
              kind: PaymentKind.online,
              label: 'Paid online',
            )
          : const PaymentMethod(
              id: 'cod',
              kind: PaymentKind.cod,
              label: 'Cash on delivery',
            ),
      subtotal: (j['subtotal'] as num).toDouble(),
      tax: (j['tax'] as num).toDouble(),
      total: (j['total'] as num).toDouble(),
      teamName: (j['team'] as Map?)?['name'] as String?,
      trackingId: (j['tracking'] as Map?)?['id'] as String?,
      carrier: (j['tracking'] as Map?)?['carrier'] as String?,
      history: [
        for (final e in (j['history'] as List? ?? const []))
          OrderEvent(
            status: '${(e as Map)['status']}',
            at: DateTime.parse('${e['at']}'),
            note: e['note'] as String?,
          ),
      ],
      status: switch (status) {
        'awaiting_payment' => OrderStatus.awaitingPayment,
        'confirmed' => OrderStatus.confirmed,
        'packed' => OrderStatus.packed,
        'processing' => OrderStatus.processing,
        'shipped' => OrderStatus.shipped,
        'delivered' => OrderStatus.delivered,
        'cancelled' => OrderStatus.cancelled,
        _ => OrderStatus.placed,
      },
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'lines': lines.map((l) => l.toJson()).toList(),
    'address': address.toJson(),
    'payment': payment.toJson(),
    'subtotal': subtotal,
    'tax': tax,
    'total': total,
    'status': status.name,
  };
  factory Order.fromJson(Map<String, Object?> j) => Order(
    id: '${j['id']}',
    createdAt: DateTime.parse('${j['createdAt']}'),
    lines: (j['lines'] as List)
        .map((e) => CartLine.fromJson((e as Map).cast()))
        .toList(),
    address: Address.fromJson((j['address'] as Map).cast()),
    payment: PaymentMethod.fromJson((j['payment'] as Map).cast()),
    subtotal: (j['subtotal'] as num).toDouble(),
    tax: (j['tax'] as num).toDouble(),
    total: (j['total'] as num).toDouble(),
    status: OrderStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => OrderStatus.placed,
    ),
  );
}

String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
String encode(Object? v) => jsonEncode(v);
