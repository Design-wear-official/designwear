import 'package:designwear/models/commerce.dart';
import 'package:designwear/services/auth/auth_service.dart';
import 'package:designwear/services/shop/cart_service.dart';
import 'package:designwear/services/shop/stores.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CartLine _line(String id, {String size = 'M', int qty = 1}) => CartLine(
  productId: id,
  title: id,
  unitPrice: 100,
  size: size,
  quantity: qty,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CartService', () {
    test('merges identical lines and computes GST', () {
      final cart = CartService()
        ..add(_line('a'))
        ..add(_line('a'))
        ..add(_line('a', size: 'L'));
      expect(cart.lines.length, 2);
      expect(cart.count, 3);
      expect(cart.subtotal, 300);
      expect(cart.tax, closeTo(54, 1e-9));
      expect(cart.total, closeTo(354, 1e-9));
    });

    test('quantity zero removes the line, and the cart persists', () async {
      final cart = CartService()..add(_line('a'));
      cart.setQuantity(cart.lines.first, 0);
      expect(cart.isEmpty, isTrue);

      cart.add(_line('b', qty: 2));
      await Future<void>.delayed(Duration.zero);
      final reloaded = CartService();
      await reloaded.load();
      expect(reloaded.count, 2);
    });
  });

  group('AuthService', () {
    test('register, sign out, sign in, wrong password, reset', () async {
      final auth = AuthService();
      expect(
        await auth.register('Asha', 'Asha@Example.com', 'short'),
        isNotNull,
      );
      expect(
        await auth.register('Asha', 'Asha@Example.com', 'longenough1'),
        isNull,
      );
      expect(auth.user!.email, 'asha@example.com');
      expect(
        await auth.register('Dup', 'asha@example.com', 'longenough1'),
        isNotNull,
      );

      await auth.signOut();
      expect(auth.isSignedIn, isFalse);
      expect(await auth.signIn('asha@example.com', 'wrongpass1'), isNotNull);
      expect(await auth.signIn('ASHA@example.com', 'longenough1'), isNull);

      expect(
        await auth.resetPassword('asha@example.com', 'brandnew123'),
        isNull,
      );
      await auth.signOut();
      expect(await auth.signIn('asha@example.com', 'longenough1'), isNotNull);
      expect(await auth.signIn('asha@example.com', 'brandnew123'), isNull);
    });

    test(
      'session survives a reload and passwords are not stored in plain text',
      () async {
        final auth = AuthService();
        await auth.register('Asha', 'asha@example.com', 'longenough1');
        final again = AuthService();
        await again.load();
        expect(again.user?.name, 'Asha');
        final raw = (await SharedPreferences.getInstance()).getString(
          'auth.users.v1',
        )!;
        expect(raw.contains('longenough1'), isFalse);
      },
    );
  });

  group('stores', () {
    test('orders round-trip through JSON', () async {
      const address = Address(
        id: 'a',
        label: 'Home',
        name: 'Asha',
        phone: '9',
        line1: '1 Rd',
        city: 'Pune',
        state: 'MH',
        pin: '411001',
      );
      final orders = OrderStore();
      await orders.upsert(
        Order(
          id: 'o1',
          createdAt: DateTime(2026, 1, 2),
          lines: [_line('a')],
          address: address,
          payment: PaymentMethodStore.cod,
          subtotal: 100,
          tax: 18,
          total: 118,
        ),
      );
      final loaded = OrderStore();
      await loaded.load();
      expect(loaded.items.single.total, 118);
      expect(loaded.items.single.address.pin, '411001');
    });
  });
}
