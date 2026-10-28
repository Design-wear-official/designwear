import 'razorpay_checkout_base.dart';

/// Platforms with no online payment (desktop).
const bool onlinePaymentSupported = false;

Future<PaymentResult> openRazorpay(PaymentRequest request) async =>
    throw const PaymentFailure(
      'Online payment is not available on this device.',
    );
