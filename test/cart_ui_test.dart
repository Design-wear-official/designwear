import 'package:designwear/models/commerce.dart';
import 'package:designwear/screens/cart/cart_screen.dart';
import 'package:designwear/screens/cart/cart_widgets.dart';
import 'package:designwear/screens/cart/checkout_screen.dart';
import 'package:designwear/services/shop/stores.dart' show PaymentMethodStore;
import 'package:designwear/services/shop/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

CartService _cartWith({int quantity = 2}) {
  final cart = CartService();
  cart.add(
    CartLine(
      productId: 'p',
      title: 'T-shirt',
      unitPrice: 500,
      size: 'XL',
      quantity: quantity,
    ),
  );
  return cart;
}

void main() {
  Future<void> open(
    WidgetTester tester,
    Widget screen,
    Size size, {
    CartService? cart,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(screen, cart: cart));
    await tester.pumpAndSettle();
  }

  group('cart', () {
    testWidgets('wide: the summary sits to the right of the items', (
      tester,
    ) async {
      await open(
        tester,
        const CartScreen(),
        const Size(1400, 900),
        cart: _cartWith(),
      );
      expect(tester.takeException(), isNull);
      final item = tester.getRect(find.byType(CartItemCard));
      final summary = tester.getRect(find.byType(SummaryCard));
      expect(summary.left, greaterThan(item.right), reason: 'two columns');
      expect(summary.width, 360);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('GST (18%)'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets(
      'phone: items, then the summary below them; nothing overflows',
      (tester) async {
        await open(
          tester,
          const CartScreen(),
          const Size(390, 844),
          cart: _cartWith(),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byType(SummaryCard)).top,
          greaterThan(tester.getRect(find.byType(CartItemCard)).bottom - 1),
        );
      },
    );

    testWidgets(
      'the stepper changes the quantity and the totals; Clear empties the cart',
      (tester) async {
        final cart = _cartWith(quantity: 1);
        await open(
          tester,
          const CartScreen(),
          const Size(1400, 900),
          cart: cart,
        );
        await tester.tap(find.byTooltip('Increase'));
        await tester.pumpAndSettle();
        expect(cart.lines.single.quantity, 2);
        await tester.tap(find.byTooltip('Decrease'));
        await tester.pumpAndSettle();
        expect(cart.lines.single.quantity, 1);
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
        expect(cart.isEmpty, isTrue);
        expect(find.text('Your cart is empty'), findsOneWidget);
        expect(find.text('Continue shopping'), findsOneWidget);
      },
    );
  });

  group('checkout', () {
    testWidgets(
      'address row, payment, the order line and the summary with Place order',
      (tester) async {
        await open(
          tester,
          const CheckoutScreen(),
          const Size(900, 1000),
          cart: _cartWith(),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Add a delivery address'), findsOneWidget);
        expect(find.textContaining('T-shirt  ×2'), findsOneWidget);
        expect(find.text('Size XL'), findsOneWidget);
        expect(find.text('Subtotal'), findsOneWidget);
        expect(find.text('Place order'), findsOneWidget);
        // No address yet: the button is disabled.
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Place order'),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets('phone width has no overflow', (tester) async {
      await open(
        tester,
        const CheckoutScreen(),
        const Size(360, 740),
        cart: _cartWith(),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('order placed card', (tester) async {
    final order = Order(
      id: 'DW1',
      createdAt: DateTime(2026, 11, 10),
      lines: [
        CartLine(productId: 'p', title: 'T-shirt', unitPrice: 500, size: 'XL'),
      ],
      address: Address(
        id: 'a',
        label: 'Home',
        name: 'Asha',
        phone: '9',
        line1: '1 Main',
        city: 'Pune',
        state: 'MH',
        pin: '411001',
      ),
      payment: PaymentMethodStore.cod,
      subtotal: 500,
      tax: 90,
      total: 590,
    );
    await open(tester, OrderPlacedScreen(order: order), const Size(800, 700));
    expect(tester.takeException(), isNull);
    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('View my orders'), findsOneWidget);
    expect(find.text('Continue shopping'), findsOneWidget);
  });
}
