import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('Razorpay')
@staticInterop
class _RazorpayJS {
  external factory _RazorpayJS(JSObject options);
}

extension on _RazorpayJS {
  external void open();
}

Future<Map<String, String>?> openRazorpayCheckoutWeb({
  required String key,
  required int amountInPaise,
  required String currency,
  required String razorpayOrderId,
  required String name,
  required String description,
  required String customerName,
}) {
  final completer = Completer<Map<String, String>?>();

  final options = JSObject();
  options['key'] = key.toJS;
  options['amount'] = amountInPaise.toJS;
  options['currency'] = currency.toJS;
  options['order_id'] = razorpayOrderId.toJS;
  options['name'] = name.toJS;
  options['description'] = description.toJS;

  final prefill = JSObject();
  prefill['name'] = customerName.toJS;
  options['prefill'] = prefill;

  final theme = JSObject();
  theme['color'] = '#000000'.toJS;
  options['theme'] = theme;

  options['handler'] = ((JSObject response) {
    if (completer.isCompleted) return;
    try {
      final paymentId =
          (response['razorpay_payment_id'] as JSString?)?.toDart ?? '';
      final orderId =
          (response['razorpay_order_id'] as JSString?)?.toDart ?? '';
      final signature =
          (response['razorpay_signature'] as JSString?)?.toDart ?? '';
      completer.complete({
        'paymentId': paymentId,
        'orderId': orderId,
        'signature': signature,
      });
    } catch (_) {
      completer.complete(null);
    }
  }).toJS;

  final modal = JSObject();
  modal['ondismiss'] = (() {
    if (!completer.isCompleted) completer.complete(null);
  }).toJS;
  options['modal'] = modal;

  try {
    final rzp = _RazorpayJS(options);
    rzp.open();
  } catch (e) {
    if (!completer.isCompleted) completer.completeError(e);
  }

  return completer.future;
}
