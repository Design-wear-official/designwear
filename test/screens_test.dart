import 'package:designwear/models/commerce.dart';
import 'package:designwear/models/models.dart'
    show CustomDesign, DesignElement, DesignElementType;
import 'package:designwear/screens/account/auth_screens.dart';
import 'package:designwear/screens/cart/cart_screen.dart';
import 'package:designwear/screens/errors/error_screen.dart';
import 'package:designwear/screens/home/home_screen.dart';
import 'package:designwear/screens/studio/editor/design_studio_screen.dart';
import 'package:designwear/screens/ai/virtual_tryon_screen.dart';
import 'package:designwear/models/product.dart';
import 'package:designwear/presentation/styles/styles.dart' show AppColors;
import 'package:designwear/services/shop/cart_service.dart';
import 'package:flutter/material.dart';

import 'package:designwear/screens/catalog/product_detail_screen.dart';
import 'package:designwear/screens/studio/editor/canvas/design_canvas_painters.dart'
    show SleevePainter;

import 'test_app.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home, {CartService? cart}) => testApp(home, cart: cart);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  _productPageTests();
  _studioViewTests();

  testWidgets('home has no bottom navigation bar', (tester) async {
    await tester.pumpWidget(_app(const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('checkout requires sign-in', (tester) async {
    final cart = CartService();
    await tester.pumpWidget(_app(const CartScreen(), cart: cart));
    cart.add(CartLine(productId: 'p', title: 'Tee', unitPrice: 500, size: 'M'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets(
    'design studio opens on a given design with its tools and publish button',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final design = CustomDesign(
        baseColor: '0xFF1A237E',
        name: 'Galaxy',
        elements: [
          DesignElement(
            id: 'g1',
            type: DesignElementType.text,
            content: 'GALAXY',
            size: 30,
          ),
        ],
      );
      await tester.pumpWidget(_app(DesignStudioScreen(initialDesign: design)));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byType(DesignStudioScreen), findsOneWidget);
      expect(find.textContaining('PUBLISH', findRichText: true), findsWidgets);
      // A design that is passed in skips the "start a design" picker.
      expect(find.text('Start a design'), findsNothing);
    },
  );

  testWidgets('try-on screen shows the action', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        const VirtualTryOnScreen(
          product: Product(id: 'p', title: 'Tee', price: 1),
        ),
      ),
    );
    expect(find.text('Try it on'), findsOneWidget);
  });

  testWidgets('error pages', (tester) async {
    await tester.pumpWidget(_app(const ErrorScreen.notFound()));
    expect(find.text('404'), findsOneWidget);
    await tester.pumpWidget(_app(const ErrorScreen.notAllowed()));
    expect(find.text('405'), findsOneWidget);
  });
}

void _studioViewTests() {
  testWidgets('remix button opens the studio on a copy of the product', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        const ProductDetailScreen(
          product: Product(
            id: 'p1',
            title: 'Graphic Tee',
            price: 499,
            stockCount: 3,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('REMIX THIS T-SHIRT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      tester.takeException(),
      isNull,
      reason: 'the studio must not overflow at this width',
    );
    expect(find.byType(DesignStudioScreen), findsOneWidget);
    expect(
      find.text('from Graphic Tee'),
      findsWidgets,
      reason: 'provenance chip names the product',
    );
  });

  testWidgets(
    'studio on a phone: view toggle and provenance chip fit without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          DesignStudioScreen(
            initialDesign: CustomDesign(name: 'S'),
            remixProduct: const Product(
              id: 'p',
              title: 'Graphic Tee',
              price: 1,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      for (final label in ['FRONT', 'BACK', 'LEFT', 'RIGHT']) {
        await tester.tap(find.text(label));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: label);
      }
    },
  );

  testWidgets(
    'studio has Front, Back, Left and Right views; sleeves are drawn',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(DesignStudioScreen(initialDesign: CustomDesign(name: 'S'))),
      );
      await tester.pump(const Duration(seconds: 1));
      for (final label in ['FRONT', 'BACK', 'LEFT', 'RIGHT']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is SleevePainter,
        ),
        findsNothing,
      );

      await tester.tap(find.text('LEFT'));
      await tester.pump(const Duration(milliseconds: 300));
      final left = tester.widgetList<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is SleevePainter,
        ),
      );
      expect(left.length, 1);
      expect((left.single.painter as SleevePainter).mirrored, isFalse);
      expect(find.text('PRINT 8 × 10 cm'), findsOneWidget);

      await tester.tap(find.text('RIGHT'));
      await tester.pump(const Duration(milliseconds: 300));
      final right = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is SleevePainter,
        ),
      );
      expect((right.painter as SleevePainter).mirrored, isTrue);

      await tester.tap(find.text('FRONT'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is SleevePainter,
        ),
        findsNothing,
      );
      expect(find.text('PRINT 30 × 40 cm'), findsOneWidget);
    },
  );
}

void _productPageTests() {
  testWidgets('product page: needs a size, then adds to the cart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cart = CartService();
    await tester.pumpWidget(
      _app(
        const ProductDetailScreen(
          product: Product(
            id: 'p1',
            title: 'Graphic Tee',
            price: 499,
            stockCount: 3,
            description: 'Soft cotton',
          ),
        ),
        cart: cart,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('GRAPHIC TEE'), findsOneWidget);
    expect(find.text('Soft cotton'), findsOneWidget);

    // The page's accents are gold, not the old neon cyan.
    expect(find.text('REMIX THIS T-SHIRT'), findsOneWidget);
    final price = tester.widget<Text>(find.text('₹499.00'));
    expect(price.style!.color, AppColors.marigold);

    await tester.tap(find.text('ADD TO CART'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Please select a size'), findsOneWidget);
    expect(cart.isEmpty, isTrue);

    await tester.tap(find.text('L'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('ADD TO CART'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(cart.lines.single.size, 'L');
    expect(cart.lines.single.title, 'Graphic Tee');
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('product page: out of stock disables buying', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        const ProductDetailScreen(
          product: Product(id: 'p2', title: 'Gone', price: 100),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Out of Stock'), findsOneWidget);
    expect(find.text('OUT OF STOCK'), findsOneWidget);
  });
}
