import 'dart:async';
import 'dart:io' show Platform;

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'razorpay_checkout_base.dart';

/// The plugin exists for Android and iOS only.
final bool onlinePaymentSupported = Platform.isAndroid || Platform.isIOS;

Future<PaymentResult> openRazorpay(PaymentRequest request) {
  if (!onlinePaymentSupported) {
    throw const PaymentFailure(
      'Online payment is not available on this device.',
    );
  }
  final razorpay = Razorpay();
  final done = Completer<PaymentResult>();

  void finish(void Function() complete) {
    if (done.isCompleted) return;
    complete();
    razorpay.clear();
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
    finish(
      () => done.complete(
        PaymentResult(
          razorpayOrderId: r.orderId ?? request.razorpayOrderId,
          paymentId: r.paymentId ?? '',
          signature: r.signature ?? '',
        ),
      ),
    );
  });
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
    // Code 0 is the person closing the sheet.
    final cancelled = r.code == Razorpay.PAYMENT_CANCELLED;
    finish(
      () => done.completeError(
        PaymentFailure(
          cancelled ? 'Payment cancelled.' : (r.message ?? 'Payment failed.'),
          cancelled: cancelled,
        ),
      ),
    );
  });

  razorpay.open({
    'key': request.keyId,
    'order_id': request.razorpayOrderId,
    'amount': request.amountPaise,
    'currency': request.currency,
    'name': 'DesignWear',
    'prefill': {
      'name': request.name,
      'email': request.email,
      'contact': request.phone,
    },
  });
  return done.future;
}
