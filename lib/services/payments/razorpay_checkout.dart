// Opens Razorpay's payment sheet. Android and iOS use the Razorpay plugin, the
// web uses Razorpay's own script, and desktop has no online payment (cash on
// delivery only).
export 'razorpay_checkout_base.dart';
export 'razorpay_checkout_stub.dart'
    if (dart.library.js_interop) 'razorpay_checkout_web.dart'
    if (dart.library.io) 'razorpay_checkout_mobile.dart';
