/// What Razorpay hands back after a successful payment. The server checks the
/// signature, so a forged result never marks an order paid.
class PaymentResult {
  const PaymentResult({
    required this.razorpayOrderId,
    required this.paymentId,
    required this.signature,
  });
  final String razorpayOrderId, paymentId, signature;
}

/// The payment was cancelled or failed; [message] is safe to show.
class PaymentFailure implements Exception {
  const PaymentFailure(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
  @override
  String toString() => message;
}

/// Everything the sheet needs, from the server's create-payment answer.
class PaymentRequest {
  const PaymentRequest({
    required this.keyId,
    required this.razorpayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.name,
    required this.email,
    required this.phone,
  });
  final String keyId, razorpayOrderId, currency, name, email, phone;
  final int amountPaise;
}
