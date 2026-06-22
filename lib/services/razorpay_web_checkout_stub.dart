import 'dart:async';

/// Non-web stub — never called because makePayment() guards with kIsWeb.
Future<Map<String, String>?> openRazorpayCheckoutWeb({
  required String key,
  required int amountInPaise,
  required String currency,
  required String razorpayOrderId,
  required String name,
  required String description,
  required String customerName,
}) async {
  throw UnsupportedError('Razorpay web checkout is only available on web');
}
