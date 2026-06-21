import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:designwear/models/models.dart';
import 'package:designwear/domain/usecases/product_use_cases.dart';
import 'package:designwear/config/config.dart';
import 'package:designwear/services/logging_service.dart';

class CartService extends ChangeNotifier {
  final Cart _cart = Cart();
  final GetTaxRateUseCase _getTaxRateUseCase;
  Timer? _syncDebounce;

  Cart get cart => _cart;
  int get itemCount => _cart.itemCount;
  double get subtotal => _cart.subtotal;
  double get tax => _cart.tax;
  double get total => _cart.total;
  List<CartItem> get items => _cart.items;
  bool get isEmpty => _cart.isEmpty;
  bool get isNotEmpty => _cart.isNotEmpty;
  bool get hasCoupon => _cart.hasCoupon;
  Coupon? get appliedCoupon => _cart.appliedCoupon;
  double get couponDiscount => _cart.couponDiscount;

  double _currentTaxRate = 18.0;
  double get currentTaxRate => _currentTaxRate;

  CartService(this._getTaxRateUseCase) {
    _init();
  }

  Future<void> _init() async {
    try {
      _currentTaxRate = await _getTaxRateUseCase();
      _cart.setTaxRate(_currentTaxRate);
      notifyListeners();
    } catch (e) {
      LoggingService.instance.logError('Error fetching tax rate', error: e);
    }

    if (WebApiConfig.useWebApi) {
      try {
        fb.FirebaseAuth.instance.authStateChanges().listen((user) {
          if (user != null) loadCartFromBackend();
        });
      } catch (e) {
        LoggingService.instance.logError('CartService: Firebase auth listener setup failed', error: e);
      }
    }
  }

  Future<Map<String, String>?> _getAuthHeaders() async {
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) return null;
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };
    } catch (e) {
      LoggingService.instance.logError('CartService: Failed to get auth token', error: e);
      return null;
    }
  }

  void _scheduleSyncToBackend() {
    if (!WebApiConfig.useWebApi) return;
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 2), _syncCartToBackend);
  }

  Future<void> _syncCartToBackend() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return;

    try {
      final response = await http.put(
        Uri.parse('${WebApiConfig.baseUrl}/cart/items'),
        headers: headers,
        body: jsonEncode({
          'items': _cart.items.map((item) => item.toJson()).toList(),
          'subtotal': _cart.subtotal,
          'tax': _cart.tax,
          'total': _cart.total,
          'itemCount': _cart.itemCount,
        }),
      );
      if (response.statusCode != 200) {
        LoggingService.instance.logWarn('Cart sync failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      LoggingService.instance.logError('Cart sync error', error: e);
    }
  }

  Future<void> loadCartFromBackend() async {
    if (!WebApiConfig.useWebApi) return;
    final headers = await _getAuthHeaders();
    if (headers == null) return;

    try {
      final response = await http.get(
        Uri.parse('${WebApiConfig.baseUrl}/cart'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final itemsJson = (data['data']['items'] as List<dynamic>?) ?? [];
          if (itemsJson.isNotEmpty) {
            final restored = itemsJson.map((raw) {
              try {
                return CartItem.fromJson(raw as Map<String, dynamic>);
              } catch (e) {
                LoggingService.instance.logWarn('CartService: skipping unrestorable item: $e');
                return null;
              }
            }).whereType<CartItem>().toList();

            if (restored.isNotEmpty) {
              _cart.items
                ..clear()
                ..addAll(restored);
              notifyListeners();
            }
          }
        }
      }
    } catch (e) {
      LoggingService.instance.logError('CartService: load from backend error', error: e);
    }
  }

  void addToCart(
    Product product, {
    int quantity = 1,
    String? size,
    CustomDesign? customDesign,
  }) {
    _cart.addItem(product, quantity: quantity, size: size, customDesign: customDesign);
    _scheduleSyncToBackend();
    notifyListeners();
  }

  void removeFromCart(String productId, {String? size}) {
    _cart.removeItem(productId, size: size);
    _scheduleSyncToBackend();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity, {String? size}) {
    _cart.updateQuantity(productId, quantity, size: size);
    _scheduleSyncToBackend();
    notifyListeners();
  }

  void incrementQuantity(String productId, {String? size}) {
    final item = _cart.items.firstWhere(
      (item) => item.product.id == productId && item.selectedSize == size,
      orElse: () => throw Exception('Item not found'),
    );
    updateQuantity(productId, item.quantity + 1, size: size);
  }

  void decrementQuantity(String productId, {String? size}) {
    final item = _cart.items.firstWhere(
      (item) => item.product.id == productId && item.selectedSize == size,
      orElse: () => throw Exception('Item not found'),
    );
    if (item.quantity > 1) {
      updateQuantity(productId, item.quantity - 1, size: size);
    } else {
      removeFromCart(productId, size: size);
    }
  }

  void clearCart() {
    _cart.clear();
    _scheduleSyncToBackend();
    notifyListeners();
  }

  void applyCoupon(Coupon coupon) {
    _cart.applyCoupon(coupon);
    notifyListeners();
  }

  void removeCoupon() {
    _cart.removeCoupon();
    notifyListeners();
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    super.dispose();
  }
}
