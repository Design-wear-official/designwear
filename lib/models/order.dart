import 'address.dart';
import 'product.dart';
import 'custom_design.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
}

extension OrderStatusX on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.confirmed: return 'Confirmed';
      case OrderStatus.processing: return 'Processing';
      case OrderStatus.shipped: return 'Shipped';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
      case OrderStatus.refunded: return 'Refunded';
    }
  }

  bool get isActive =>
      this != OrderStatus.delivered &&
      this != OrderStatus.cancelled &&
      this != OrderStatus.refunded;

  bool get isFinal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.refunded;
}

class OrderItem {
  final String productId;
  final String productTitle;
  final String? productImageUrl;
  final double price;
  final int quantity;
  final String? selectedSize;
  final String? selectedColor;
  final CustomDesign? customDesign;

  const OrderItem({
    required this.productId,
    required this.productTitle,
    this.productImageUrl,
    required this.price,
    required this.quantity,
    this.selectedSize,
    this.selectedColor,
    this.customDesign,
  });

  double get total => price * quantity;

  factory OrderItem.fromProduct(
    Product product, {
    required int quantity,
    String? size,
    String? color,
    CustomDesign? customDesign,
  }) {
    return OrderItem(
      productId: product.id,
      productTitle: product.title,
      productImageUrl: product.imageUrl,
      price: product.price,
      quantity: quantity,
      selectedSize: size,
      selectedColor: color,
      customDesign: customDesign,
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      productTitle: json['productTitle'] ?? '',
      productImageUrl: json['productImageUrl'],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      selectedSize: json['selectedSize'],
      selectedColor: json['selectedColor'],
      customDesign: json['customDesign'] != null
          ? CustomDesign.fromJson(json['customDesign'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'price': price,
      'quantity': quantity,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'customDesign': customDesign?.toJson(),
    };
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final OrderStatus status;
  final Address shippingAddress;
  final double subtotal;
  final double tax;
  final double discount;
  final double shippingFee;
  final double total;
  final String? couponCode;
  final String? paymentId; // Razorpay payment ID
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final String? trackingNumber;
  final String? trackingUrl;
  final String? notes;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.status,
    required this.shippingAddress,
    required this.subtotal,
    required this.tax,
    this.discount = 0,
    this.shippingFee = 0,
    required this.total,
    this.couponCode,
    this.paymentId,
    this.paymentMethod,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.trackingNumber,
    this.trackingUrl,
    this.notes,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get hasCustomDesigns => items.any((item) => item.customDesign != null);

  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    OrderStatus? status,
    Address? shippingAddress,
    double? subtotal,
    double? tax,
    double? discount,
    double? shippingFee,
    double? total,
    String? couponCode,
    String? paymentId,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    String? trackingNumber,
    String? trackingUrl,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? List.from(this.items),
      status: status ?? this.status,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      shippingFee: shippingFee ?? this.shippingFee,
      total: total ?? this.total,
      couponCode: couponCode ?? this.couponCode,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      notes: notes ?? this.notes,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
      status: _statusFromString(json['status'] ?? 'pending'),
      shippingAddress: Address.fromJson(json['shippingAddress'] ?? {}),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      couponCode: json['couponCode'],
      paymentId: json['paymentId'],
      paymentMethod: json['paymentMethod'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'])
          : null,
      trackingNumber: json['trackingNumber'],
      trackingUrl: json['trackingUrl'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'status': status.name,
      'shippingAddress': shippingAddress.toJson(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'shippingFee': shippingFee,
      'total': total,
      'couponCode': couponCode,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'trackingNumber': trackingNumber,
      'trackingUrl': trackingUrl,
      'notes': notes,
    };
  }

  static OrderStatus _statusFromString(String s) {
    final map = {
      'pending': OrderStatus.pending,
      'confirmed': OrderStatus.confirmed,
      'processing': OrderStatus.processing,
      'shipped': OrderStatus.shipped,
      'out_for_delivery': OrderStatus.outForDelivery,
      'outForDelivery': OrderStatus.outForDelivery,
      'delivered': OrderStatus.delivered,
      'cancelled': OrderStatus.cancelled,
      'refunded': OrderStatus.refunded,
    };
    return map[s] ?? OrderStatus.pending;
  }
}
