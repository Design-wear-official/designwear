import 'custom_design.dart';
import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String? selectedSize;
  CustomDesign? customDesign;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedSize,
    this.customDesign,
  });

  double get total => product.price * quantity;
}

class Cart {
  final List<CartItem> items;

  Cart({List<CartItem>? items}) : items = items ?? [];

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double taxRate = 0.18; // 18% GST (updated via setTaxRate from API)

  void setTaxRate(double rate) {
    taxRate = rate / 100.0;
  }

  double get tax => subtotal * taxRate;

  double get total => subtotal + tax;

  void addItem(
    Product product, {
    int quantity = 1,
    String? size,
    CustomDesign? customDesign,
  }) {
    // If it's a custom design, we might treat it as unique or check equality of design
    // For simplicity, let's say custom designs are always unique entries for now
    if (customDesign != null) {
      items.add(
        CartItem(
          product: product,
          quantity: quantity,
          selectedSize: size,
          customDesign: customDesign,
        ),
      );
      return;
    }

    final existingIndex = items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedSize == size &&
          item.customDesign == null,
    );

    if (existingIndex >= 0) {
      items[existingIndex].quantity += quantity;
    } else {
      items.add(
        CartItem(product: product, quantity: quantity, selectedSize: size),
      );
    }
  }

  void removeItem(String productId, {String? size}) {
    items.removeWhere(
      (item) => item.product.id == productId && item.selectedSize == size,
    );
  }

  void updateQuantity(String productId, int quantity, {String? size}) {
    final index = items.indexWhere(
      (item) => item.product.id == productId && item.selectedSize == size,
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
  }

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;
}
