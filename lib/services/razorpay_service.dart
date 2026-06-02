import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:designwear/config/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

  final String? _baseUrl = WebApiConfig.useWebApi ? WebApiConfig.baseUrl : null;

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};

    // Always try to get a fresh Firebase ID token
    final firebaseUser = fb.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final idToken = await firebaseUser.getIdToken(true);
        if (idToken != null && idToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $idToken';
          return headers;
        }
      } catch (e) {
        debugPrint('Failed to get fresh Firebase ID token: $e');
      }
    }

    // Fallback: use stored token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Opens the Razorpay native checkout and returns true if payment succeeded.
  Future<bool> makePayment({
    required String orderId,
    required double amount,
    required String customerName,
  }) async {
    if (_baseUrl == null) {
      debugPrint('Web API is disabled. Cannot process Razorpay payment.');
      return false;
    }

    final completer = Completer<bool>();
    final razorpay = Razorpay();

    void onPaymentSuccess(PaymentSuccessResponse response) {
      debugPrint('Razorpay payment success: ${response.paymentId}');
      _verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      ).then((verified) {
        if (!completer.isCompleted) completer.complete(verified);
      });
    }

    void onPaymentError(PaymentFailureResponse response) {
      debugPrint('Razorpay payment failed: ${response.message}');
      if (!completer.isCompleted) completer.complete(false);
    }

    void onExternalWallet(ExternalWalletResponse response) {
      debugPrint('External wallet: ${response.walletName}');
      // External wallet payments cannot be verified immediately
      if (!completer.isCompleted) completer.complete(false);
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onPaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onPaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);

    try {
      // 1. Create Razorpay order on backend
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/razorpay/order'),
        headers: headers,
        body: jsonEncode({'order_id': orderId}),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to create Razorpay order: ${response.body}');
        razorpay.clear();
        return false;
      }

      final data = jsonDecode(response.body);

      // 2. Open Razorpay checkout
      final options = {
        'key': data['key_id'],
        'amount': data['amount'], // already in paise
        'currency': data['currency'] ?? 'INR',
        'order_id': data['razorpay_order_id'],
        'name': 'Design Wear',
        'description': 'Order #$orderId',
        'prefill': {
          'name': customerName,
        },
        'theme': {
          'color': '#000000',
        },
      };

      razorpay.open(options);

      final result = await completer.future;
      razorpay.clear();
      return result;
    } catch (e) {
      debugPrint('Error in Razorpay makePayment: $e');
      razorpay.clear();
      return false;
    }
  }

  /// Calls our backend to verify the Razorpay payment signature.
  Future<bool> _verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/razorpay/verify'),
        headers: headers,
        body: jsonEncode({
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      debugPrint('Payment verification failed: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error verifying Razorpay payment: $e');
      return false;
    }
  }
}
