import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../config/gokwik_config.dart';
import 'cart_service.dart';

class OrderService {
  final String? _baseUrl = WebApiConfig.useWebApi ? WebApiConfig.baseUrl : null;

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Creates an order in the Node.js API based on the current cart
  Future<bool> createOrder(
    CartService cartService,
    Map<String, dynamic> shippingAddress,
    String notes,
  ) async {
    if (_baseUrl == null) {
      // If we are solely depending on Sanity, order creation is likely handled by a different webhook
      debugPrint('Web API is disabled. Cannot create order via API.');
      return false;
    }

    try {
      final headers = await _getHeaders();

      // Prepare payload to match order router format
      final payload = {
        'items': cartService.items
            .map(
              (item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
                'size': item.selectedSize,
                'color': item.customDesign?.baseColor,
              },
            )
            .toList(),
        'shipping_address': shippingAddress,
        'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/orders'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        debugPrint('Order created successfully: ${response.body}');
        return true;
      } else {
        debugPrint('Order creation failed with status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Order creation exception: $e');
      return false;
    }
  }
}
