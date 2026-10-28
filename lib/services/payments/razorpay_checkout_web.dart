import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'razorpay_checkout_base.dart';

const bool onlinePaymentSupported = true;

const _scriptUrl = 'https://checkout.razorpay.com/v1/checkout.js';

@JS('Razorpay')
extension type _Razorpay._(JSObject _) implements JSObject {
  external factory _Razorpay(JSObject options);
  external void open();
  external void on(String event, JSFunction handler);
}

Future<void>? _loading;

// Razorpay's script is loaded on first use, not at app start.
Future<void> _loadScript() {
  return _loading ??= () {
    final loaded = Completer<void>();
    final script = web.HTMLScriptElement()
      ..src = _scriptUrl
      ..async = true;
    script.onload = ((web.Event _) => loaded.complete()).toJS;
    script.onerror = ((web.Event _) {
      _loading = null;
      loaded.completeError(
        const PaymentFailure(
          'Could not load the payment page. Check your connection.',
        ),
      );
    }).toJS;
    web.document.head!.append(script);
    return loaded.future;
  }();
}

Future<PaymentResult> openRazorpay(PaymentRequest request) async {
  await _loadScript();
  final done = Completer<PaymentResult>();

  final options =
      <String, Object?>{
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
          }.jsify()
          as JSObject;

  options.setProperty(
    'handler'.toJS,
    ((JSObject response) {
      String field(String key) =>
          (response.getProperty<JSString?>(key.toJS))?.toDart ?? '';
      if (done.isCompleted) return;
      done.complete(
        PaymentResult(
          razorpayOrderId: field('razorpay_order_id'),
          paymentId: field('razorpay_payment_id'),
          signature: field('razorpay_signature'),
        ),
      );
    }).toJS,
  );
  options.setProperty(
    'modal'.toJS,
    <String, Object?>{
      'ondismiss': (() {
        if (!done.isCompleted) {
          done.completeError(
            const PaymentFailure('Payment cancelled.', cancelled: true),
          );
        }
      }).toJS,
    }.jsify(),
  );

  final checkout = _Razorpay(options);
  checkout.on(
    'payment.failed',
    ((JSObject response) {
      final error = response.getProperty<JSObject?>('error'.toJS);
      final message = (error?.getProperty<JSString?>('description'.toJS))
          ?.toDart;
      if (!done.isCompleted) {
        done.completeError(PaymentFailure(message ?? 'Payment failed.'));
      }
    }).toJS,
  );
  checkout.open();
  return done.future;
}
