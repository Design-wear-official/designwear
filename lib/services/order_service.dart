import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:designwear/config/config.dart';
import 'cart_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Thrown when the backend returns a 401 Unauthorized (e.g. token expired).
class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class OrderService {
  final String? _baseUrl = WebApiConfig.useWebApi ? WebApiConfig.baseUrl : null;

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};

    // Always try to get a fresh Firebase ID token (auto-refreshes if expired)
    final firebaseUser = fb.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final idToken = await firebaseUser.getIdToken(true); // force refresh
        if (idToken != null && idToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $idToken';
          return headers;
        }
      } catch (e) {
        debugPrint('Failed to get fresh Firebase ID token: $e');
      }
    }

    // Fallback: use stored token (may be expired)
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Creates an order in the Node.js API based on the current cart
  Future<String?> createOrder(
    CartService cartService,
    Map<String, dynamic> shippingAddress,
    String notes,
  ) async {
    if (_baseUrl == null) {
      debugPrint('Web API is disabled. Cannot create order via API.');
      return null;
    }

    try {
      final headers = await _getHeaders();

      final payload = {
        'items': cartService.items
            .map(
              (item) => {
                'product_id': item.product.id,
                'title': item.product.title,
                'quantity': item.quantity,
                'price': item.product.price,
                'size': item.selectedSize,
                'color': item.customDesign?.baseColor,
              },
            )
            .toList(),
        'shippingAddress': shippingAddress,
        'billingAddress': shippingAddress,
        'totalAmount': cartService.total,
        'paymentMethod': 'RAZORPAY',
        'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/orders'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        debugPrint('Order created successfully: ${response.body}');
        final data = jsonDecode(response.body);
        return data['data']['id']; // Return the Firestore document ID
      } else if (response.statusCode == 401) {
        debugPrint('Order creation failed with 401: ${response.body}');
        throw UnauthorizedException('Session expired. Please login again.');
      } else {
        debugPrint('Order creation failed with status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      debugPrint('Order creation exception: $e');
      return null;
    }
  }

  /// Fetches the current user's order history from the Node.js API
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    if (_baseUrl == null) {
      debugPrint('Web API is disabled. Cannot fetch orders.');
      return [];
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/orders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      debugPrint('Fetch orders failed: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }
}
