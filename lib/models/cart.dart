import 'custom_design.dart';
import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String? selectedSize;
  String? selectedColor;
  CustomDesign? customDesign;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedSize,
    this.selectedColor,
    this.customDesign,
  });

  double get total => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': product.id,
      'product': product.toJson(),
      'quantity': quantity,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productData = json['product'];
    if (productData == null) throw Exception('Missing product data in cart item');
    return CartItem(
      product: Product.fromApiMap(productData as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      selectedSize: json['selectedSize'] as String?,
      selectedColor: json['selectedColor'] as String?,
    );
  }
}

class Coupon {
  final String code;
  final double discountPercent;
  final double? maxDiscountAmount;
  final double? minOrderAmount;
  final bool isValid;

  const Coupon({
    required this.code,
    required this.discountPercent,
    this.maxDiscountAmount,
    this.minOrderAmount,
    this.isValid = true,
  });

  double discountFor(double subtotal) {
    if (!isValid) return 0;
    if (minOrderAmount != null && subtotal < minOrderAmount!) return 0;
    final discount = subtotal * (discountPercent / 100);
    if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
      return maxDiscountAmount!;
    }
    return discount;
  }
}

class Cart {
  final List<CartItem> items;
  Coupon? appliedCoupon;

  Cart({List<CartItem>? items, this.appliedCoupon}) : items = items ?? [];

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);

  double taxRate = 0.18; // 18% GST

  void setTaxRate(double rate) => taxRate = rate / 100.0;

  double get couponDiscount => appliedCoupon?.discountFor(subtotal) ?? 0;

  double get discountedSubtotal => subtotal - couponDiscount;

  double get tax => discountedSubtotal * taxRate;

  double get total => discountedSubtotal + tax;

  void applyCoupon(Coupon coupon) => appliedCoupon = coupon;

  void removeCoupon() => appliedCoupon = null;

  void addItem(
    Product product, {
    int quantity = 1,
    String? size,
    String? color,
    CustomDesign? customDesign,
  }) {
    if (customDesign != null) {
      items.add(CartItem(
        product: product,
        quantity: quantity,
        selectedSize: size,
        selectedColor: color,
        customDesign: customDesign,
      ));
      return;
    }

    final existingIndex = items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedSize == size &&
          item.selectedColor == color &&
          item.customDesign == null,
    );

    if (existingIndex >= 0) {
      items[existingIndex].quantity += quantity;
    } else {
      items.add(CartItem(
        product: product,
        quantity: quantity,
        selectedSize: size,
        selectedColor: color,
      ));
    }
  }

  void removeItem(String productId, {String? size, String? color}) {
    items.removeWhere(
      (item) =>
          item.product.id == productId &&
          item.selectedSize == size &&
          item.selectedColor == color,
    );
  }

  void updateQuantity(String productId, int quantity, {String? size, String? color}) {
    final index = items.indexWhere(
      (item) =>
          item.product.id == productId &&
          item.selectedSize == size &&
          item.selectedColor == color,
    );

    if (index >= 0) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index].quantity = quantity;
      }
    }
  }

  void clear() {
    items.clear();
    appliedCoupon = null;
  }

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  bool get hasCoupon => appliedCoupon != null && appliedCoupon!.isValid;
}
