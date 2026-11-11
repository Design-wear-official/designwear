import 'dart:convert';

import 'package:designwear/cms/cms_config.dart';
import 'package:designwear/cms/cms_service.dart';
import 'package:designwear/data/product_repository.dart';
import 'package:designwear/models/commerce.dart';
import 'package:designwear/models/product.dart';
import 'package:designwear/models/watch.dart';
import 'package:designwear/screens/cart/cart_screen.dart';
import 'package:designwear/screens/catalog/product_detail_screen.dart';
import 'package:designwear/screens/home/home_screen.dart';
import 'package:designwear/services/shop/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_app.dart';

Map<String, Object?> _watchRecord({
  String id = 'w1',
  String title = 'Meridian 40',
  num price = 2499,
  Map<String, Object?> watch = const {},
  List<String> variants = const ['Black leather', 'Steel mesh'],
}) => {
  'id': id,
  'title': title,
  'price': price,
  'stockCount': 4,
  'productType': 'watch',
  'categoryId': 'watches',
  'variantLabel': 'Strap',
  'variants': variants,
  'watch': {
    'brand': 'DesignWear',
    'gender': 'Unisex',
    'caseSizeMm': 40,
    'caseMaterial': 'Stainless steel',
    'dialColor': 'Black',
    'strapMaterial': 'Leather',
    'strapWidthMm': '20 mm',
    'movement': 'Quartz',
    'display': 'Analog',
    'waterResistanceM': 30,
    'warrantyMonths': 12,
    'countryOfOrigin': 'India',
    'inTheBox': ['Watch', 'Warranty card'],
    ...watch,
  },
};

ProductRepository _repo(List<Map<String, Object?>> records) =>
    ProductRepository(
      cms: CmsService(
        const CmsConfig(
          baseUrl: 'https://cms.example.com',
          connectionId: 'c',
          viewerToken: 't',
        ),
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'data': records, 'nextCursor': null, 'limit': 40}),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      ),
    );

void main() {
  group('watch records', () {
    test('a watch record parses its specs and strap options', () {
      final p = Product.fromRecord(_watchRecord());
      expect(p.isWatch, isTrue);
      expect(p.isGarment, isFalse);
      expect(p.options, ['Black leather', 'Steel mesh']);
      expect(p.optionLabel, 'Strap');
      final w = p.watch!;
      expect(w.caseSizeMm, 40);
      expect(w.strapWidthMm, 20, reason: 'numbers may arrive as "20 mm"');
      expect(w.summary, '40 mm · Quartz · Leather strap');
      expect(w.waterResistanceLabel, '30 m (3 ATM)');
      expect(w.waterResistanceAdvice, contains('Take it off to shower'));
      expect(w.warrantyLabel, '1 year');
      expect(w.fitAdvice, contains('mid-sized'));
      expect(w.specRows.map((r) => r.$1), contains('Country of origin'));
    });

    test('a garment is unchanged: clothing sizes, not a watch', () {
      final p = Product.fromRecord({'id': 'p', 'title': 'Tee', 'price': 499});
      expect(p.isWatch, isFalse);
      expect(p.watch, isNull);
      expect(p.options, ['S', 'M', 'L', 'XL', 'XXL']);
      expect(p.optionLabel, 'Size');
    });

    test('a watch marked only by category has no size to choose', () {
      final p = Product.fromRecord({
        'id': 'w',
        'title': 'Plain watch',
        'price': 999,
        'categoryId': 'watches',
      });
      expect(p.isWatch, isTrue);
      expect(p.options, isEmpty);
    });
  });

  group('watch filters', () {
    final watches = [
      Product.fromRecord(_watchRecord()),
      Product.fromRecord(
        _watchRecord(
          id: 'w2',
          title: 'Tide 44',
          watch: {
            'caseSizeMm': 44,
            'strapMaterial': 'Silicone',
            'movement': 'Automatic',
            'dialColor': 'Blue',
          },
        ),
      ),
    ];

    test('facets list only the values that differ', () {
      final options = WatchFilter.options(watches);
      expect(options[WatchFacet.strap], ['Leather', 'Silicone']);
      expect(options[WatchFacet.caseSize], ['38 to 42 mm', 'Over 42 mm']);
      expect(
        options.containsKey(WatchFacet.gender),
        isFalse,
        reason: 'both are Unisex, so it filters nothing',
      );
    });

    test('values in a facet are alternatives; facets combine', () {
      var f = const WatchFilter().toggle(WatchFacet.strap, 'Leather');
      expect(watches.where(f.matches).map((p) => p.id), ['w1']);
      f = f.toggle(WatchFacet.strap, 'Silicone');
      expect(watches.where(f.matches), hasLength(2));
      f = f.toggle(WatchFacet.movement, 'Automatic');
      expect(watches.where(f.matches).map((p) => p.id), ['w2']);
      expect(f.count, 3);
      f = f.toggle(WatchFacet.movement, 'Automatic');
      expect(watches.where(f.matches), hasLength(2));
    });
  });

  group('cart lines', () {
    test('a watch goes in with its strap; the label follows it', () {
      final cart = CartService();
      cart.addToCart(Product.fromRecord(_watchRecord()), size: 'Steel mesh');
      final line = cart.lines.single;
      expect(line.size, 'Steel mesh');
      expect(line.optionText, 'Strap: Steel mesh');
      final restored = CartLine.fromJson(
        (jsonDecode(jsonEncode(line.toJson())) as Map).cast(),
      );
      expect(restored.optionText, 'Strap: Steel mesh');
    });

    test('a one-version watch has no option text; garments keep "Size"', () {
      final cart = CartService();
      cart.addToCart(Product.fromRecord(_watchRecord(variants: const [])));
      expect(cart.lines.single.size, Product.oneSize);
      expect(cart.lines.single.optionText, '');

      expect(
        CartLine(
          productId: 'p',
          title: 'Tee',
          unitPrice: 1,
          size: 'XL',
        ).optionText,
        'Size XL',
      );
      // A line the server returned without a label: show the value alone.
      expect(
        CartLine.fromJson({
          'productId': 'w',
          'title': 'Watch',
          'unitPrice': 10,
          'size': 'Black leather',
        }).optionText,
        'Black leather',
      );
    });
  });

  group('screens', () {
    Future<void> size(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('home: the Watches chip shows watches and their filters', (
      tester,
    ) async {
      await size(tester, const Size(1400, 1600));
      await tester.pumpWidget(
        testApp(
          HomeScreen(
            repository: _repo([
              {'id': 'p1', 'title': 'Graphic Tee', 'price': 499},
              _watchRecord(),
              _watchRecord(
                id: 'w2',
                title: 'Tide 44',
                watch: {'strapMaterial': 'Silicone', 'caseSizeMm': 44},
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ALL PRODUCTS'), findsOneWidget);
      expect(find.text('Graphic Tee'), findsOneWidget);
      expect(find.text('Meridian 40'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Watches'));
      await tester.pumpAndSettle();
      expect(find.text('WATCHES'), findsOneWidget);
      expect(find.text('Graphic Tee'), findsNothing);
      expect(find.text('Meridian 40'), findsOneWidget);
      expect(find.text('40 mm · Quartz · Leather strap'), findsOneWidget);

      await tester.tap(find.text('Strap'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Silicone').last);
      await tester.pumpAndSettle();
      expect(find.text('Strap (1)'), findsOneWidget);
      expect(find.text('Meridian 40'), findsNothing);
      expect(find.text('Tide 44'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Meridian 40'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Clothing'));
      await tester.pumpAndSettle();
      expect(find.text('Graphic Tee'), findsOneWidget);
      expect(find.text('Meridian 40'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('home: no category chips while the catalog has no watches', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          HomeScreen(
            repository: _repo([
              {'id': 'p1', 'title': 'Graphic Tee', 'price': 499},
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Watches'), findsNothing);
    });

    testWidgets(
      'watch page: specs and fit, no remix or try-on, strap then cart',
      (tester) async {
        await size(tester, const Size(600, 3000));
        final cart = CartService();
        await tester.pumpWidget(
          testApp(
            ProductDetailScreen(product: Product.fromRecord(_watchRecord())),
            cart: cart,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.text('Specifications'), findsOneWidget);
        expect(find.text('Case size'), findsOneWidget);
        expect(find.text('30 m (3 ATM)'), findsOneWidget);
        expect(find.text('Size and fit'), findsOneWidget);
        expect(find.text('1 year warranty'), findsOneWidget);
        expect(find.text('Watch, Warranty card'), findsOneWidget);
        expect(find.text('REMIX THIS T-SHIRT'), findsNothing);
        expect(find.text('Try It On Virtually ✨'), findsNothing);
        expect(find.text('Select Strap'), findsOneWidget);
        expect(find.text('XL'), findsNothing);

        await tester.tap(find.text('ADD TO CART'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Please select a strap'), findsOneWidget);
        expect(cart.isEmpty, isTrue);

        await tester.tap(find.text('Steel mesh'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('ADD TO CART'));
        await tester.pump(const Duration(milliseconds: 600));
        expect(cart.lines.single.size, 'Steel mesh');
        await tester.pumpAndSettle(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'watch page on desktop: no overflow, specs beside the picture',
      (tester) async {
        await size(tester, const Size(1440, 1400));
        await tester.pumpWidget(
          testApp(
            ProductDetailScreen(
              product: Product.fromRecord(_watchRecord(variants: const [])),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.text('Specifications'), findsOneWidget);
        expect(find.text('Remix this T-shirt'), findsNothing);
        expect(find.textContaining('to continue'), findsNothing);
        expect(find.text('Add to cart'), findsOneWidget);
      },
    );

    testWidgets('cart shows the strap, not "Size"', (tester) async {
      await size(tester, const Size(1400, 900));
      final cart = CartService()
        ..addToCart(Product.fromRecord(_watchRecord()), size: 'Black leather');
      await tester.pumpWidget(testApp(const CartScreen(), cart: cart));
      await tester.pumpAndSettle();
      expect(find.text('Strap: Black leather'), findsOneWidget);
      expect(find.textContaining('Size '), findsNothing);
    });
  });
}
