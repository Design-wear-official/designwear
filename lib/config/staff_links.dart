import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Where staff do their work. Public addresses, not secrets; override with
/// STAFF_APP_URL / SETHUCMS_ADMIN_URL in .env.
class StaffLinks {
  StaffLinks._();

  /// The DesignWear Staff app: orders, returns, payouts and stock for each role.
  static String get staffApp =>
      _read('STAFF_APP_URL', 'https://designwear-scm.vercel.app');

  /// The SethuCMS admin: the catalog (products), teams and content.
  static String get cmsAdmin =>
      _read('SETHUCMS_ADMIN_URL', 'https://sethucms-admin.vercel.app');

  static String _read(String key, String fallback) {
    String? value;
    try {
      value = dotenv.env[key];
    } catch (_) {
      // dotenv not loaded (tests): use the default.
    }
    final v = (value ?? '').trim();
    return Uri.tryParse(v)?.scheme == 'https' ? v : fallback;
  }

  static const roleLabels = {
    'vendor': 'Vendor',
    'desk': 'Order desk',
    'delivery': 'Delivery partner',
    'owner': 'Owner',
  };

  /// What this role works on, for the profile row.
  static String describe(String role) => switch (role) {
    'vendor' => 'Confirm and pack your team’s orders, stock and payouts',
    'desk' => 'New orders, assign a vendor, returns',
    'delivery' => 'Ship, deliver and collect cash',
    'owner' => 'Every order, returns, refunds and payouts',
    _ => 'Open the staff app',
  };
}
