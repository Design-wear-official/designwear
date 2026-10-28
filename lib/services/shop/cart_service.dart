import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/api_client.dart';
import '../../models/commerce.dart';
import '../../models/product.dart';
import '../../logging/app_log.dart';

class CartService extends ChangeNotifier {
  CartService({this.api});

  /// When set and signed in, the cart is mirrored to the server so it follows
  /// the account across devices. Prices shown are estimates; the server
  /// re-prices at checkout.
  final ApiClient? api;

  static const taxRate = 0.18;
  static const _key = 'cart.v1';

  final List<CartLine> _lines = [];
  List<CartLine> get lines => List.unmodifiable(_lines);
  int get count => _lines.fold(0, (n, l) => n + l.quantity);
  double get subtotal => _lines.fold(0, (s, l) => s + l.total);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax;
  bool get isEmpty => _lines.isEmpty;

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) {
        _lines
          ..clear()
          ..addAll(
            (jsonDecode(raw) as List).map(
              (e) => CartLine.fromJson((e as Map).cast()),
            ),
          );
        notifyListeners();
      }
    } catch (e) {
      AppLog.instance.warning('cart', 'Could not load cart', e);
    }
  }

  Future<void> _save() async {
    _pushToServer();
    try {
      await (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode(_lines.map((l) => l.toJson()).toList()),
      );
    } catch (e) {
      AppLog.instance.warning('cart', 'Could not save cart', e);
    }
  }

  Timer? _pushTimer;

  @override
  void dispose() {
    _pushTimer?.cancel();
    super.dispose();
  }

  /// Coalesces rapid changes (e.g. tapping +/-) into one request.
  void _pushToServer() {
    if (api == null) return;
    _pushTimer?.cancel();
    _pushTimer = Timer(const Duration(milliseconds: 600), _pushNow);
  }

  void _pushNow() {
    final api = this.api;
    if (api == null || !api.hasToken) return;
    api
        .put('/v1/cart', {
          'lines': [
            for (final l in _lines)
              {
                'productId': l.productId,
                'designId': l.designId,
                'size': l.size,
                'quantity': l.quantity,
              },
          ],
        })
        .then<void>(
          (_) {},
          onError: (Object e) =>
              AppLog.instance.warning('cart', 'Cart sync failed', e),
        );
  }

  /// After sign-in: merge the server cart into the local one.
  Future<void> syncFromServer() async {
    final api = this.api;
    if (api == null || !api.hasToken) return;
    try {
      final j = await api.get('/v1/cart');
      for (final raw in (j['lines'] as List? ?? const [])) {
        final l = CartLine.fromJson((raw as Map).cast());
        if (!_lines.any((x) => x.key == l.key)) _lines.add(l);
      }
      notifyListeners();
      await _save();
    } on ApiException catch (_) {}
  }

  /// On sign-out in server mode, so the next person doesn't see this cart.
  void clearLocal() {
    _lines.clear();
    notifyListeners();
    SharedPreferences.getInstance().then(
      (p) => p.remove(_key),
      onError: (_) => false,
    );
  }

  /// Adds a catalog product (one unit) in the given size.
  void addToCart(Product product, {String? size}) => add(
    CartLine(
      productId: product.id,
      title: product.title,
      unitPrice: product.price,
      size: size ?? 'M',
      imageUrl: product.displayImageUrl,
    ),
  );

  void add(CartLine line) {
    final existing = _lines.where((l) => l.key == line.key);
    if (existing.isNotEmpty) {
      existing.first.quantity += line.quantity;
    } else {
      _lines.add(line);
    }
    notifyListeners();
    _save();
  }

  void setQuantity(CartLine line, int quantity) {
    if (quantity <= 0) {
      _lines.remove(line);
    } else {
      line.quantity = quantity.clamp(1, 99);
    }
    notifyListeners();
    _save();
  }

  void remove(CartLine line) => setQuantity(line, 0);

  void clear() {
    _lines.clear();
    notifyListeners();
    _save();
  }
}
