import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  final String? _baseUrl = WebApiConfig.useWebApi ? WebApiConfig.baseUrl : null;

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Initializes and displays the Stripe Payment Sheet
  Future<bool> makePayment({
    required String orderId,
    required double amount,
    required String customerName,
  }) async {
    if (_baseUrl == null) {
      debugPrint('Web API is disabled. Cannot process Stripe payment.');
      return false;
    }

    try {
      // 1. Create Payment Intent on our backend
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/stripe/checkout'),
        headers: headers,
        body: jsonEncode({'order_id': orderId}),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to create payment intent: ${response.body}');
        return false;
      }

      final data = jsonDecode(response.body);
      final String clientSecret = data['client_secret'];

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Design Wear',
          customerEphemeralKeySecret: data['ephemeralKey'], // If backend provides it
          customerId: data['customer'], // If backend provides it
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.black,
            ),
          ),
        ),
      );

      // 3. Display Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      debugPrint('Payment successful');
      return true;
    } on StripeException catch (e) {
      debugPrint('Stripe exception: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      debugPrint('Error in makePayment: $e');
      return false;
    }
  }
}
