import 'dart:convert';

import 'package:designwear/cms/cms_config.dart';
import 'package:designwear/cms/cms_service.dart';
import 'package:designwear/data/product_repository.dart';
import 'package:designwear/models/models.dart'
    show CustomDesign, DesignElement, DesignSide;
import 'package:designwear/models/product.dart';
import 'package:designwear/screens/home/home_screen.dart';

import 'test_app.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ProductRepository _repo(List<Map<String, Object?>> records) {
  final mock = MockClient(
    (_) async => http.Response(
      jsonEncode({
        'data': records,
        'nextCursor': null,
        'limit': 40,
        'notes': [],
      }),
      200,
      headers: {'content-type': 'application/json'},
    ),
  );
  return ProductRepository(
    cms: CmsService(
      const CmsConfig(
        baseUrl: 'https://cms.example.com',
        connectionId: 'c',
        viewerToken: 't',
      ),
      httpClient: mock,
    ),
  );
}

void main() {
  test('Product parses flat and Sanity-style records', () {
    final flat = Product.fromRecord({
      'id': 'p1',
      'title': 'Tee',
      'price': 499,
      'originalPrice': 999,
      'stockCount': 3,
      'slug': 'tee',
    });
    expect(flat.discountPercent, 50);
    expect(flat.isInStock, isTrue);

    final sanity = Product.fromRecord({
      '_id': 'p2',
      'title': 'Hoodie',
      'price': '1299.5',
      'slug': {'current': 'hoodie'},
      'stock': 0,
      'category': {'_ref': 'cat1'},
    });
    expect(sanity.id, 'p2');
    expect(sanity.slug, 'hoodie');
    expect(sanity.categoryId, 'cat1');
    expect(sanity.isInStock, isFalse);
  });

  test('design sides: sleeves parse and round-trip; unknown values fall back to front', () {
    expect(DesignSide.fromString('left'), DesignSide.left);
    expect(DesignSide.fromString('right'), DesignSide.right);
    expect(DesignSide.fromString('back'), DesignSide.back);
    expect(DesignSide.fromString('nonsense'), DesignSide.front);
    expect(DesignSide.fromString(null), DesignSide.front);
    expect(DesignSide.left.isSleeve && DesignSide.right.isSleeve, isTrue);
    expect(DesignSide.front.isSleeve || DesignSide.back.isSleeve, isFalse);
    final el = DesignElement(id: 'a', content: 'HI', side: DesignSide.right);
    expect(DesignElement.fromJson(el.toJson()).side, DesignSide.right);
    final design = CustomDesign(
      elements: [
        el,
        DesignElement(id: 'b', content: 'F'),
      ],
    );
    expect(design.elementsForSide(DesignSide.right).single.id, 'a');
    expect(design.elementsForSide(DesignSide.front).single.id, 'b');
  });

  test('remixes and unpriced entries are not listable; originals are', () {
    bool listable(Map<String, Object?> m) => Product.fromRecord(m).isListable;
    expect(listable({'id': 'a', 'title': 'T-shirt', 'price': 10}), isTrue);
    expect(
      listable({'id': 'b', 'title': 'Remix by @kasinadh', 'price': 499}),
      isFalse,
    );
    expect(
      listable({
        'id': 'c',
        'title': 'Cool',
        'price': 499,
        'remixedFromHandle': 'asha',
      }),
      isFalse,
    );
    expect(listable({'id': 'd', 'title': 'Midnight', 'price': 0}), isFalse);
    // A creator credit alone does not make something a remix.
    expect(
      listable({
        'id': 'e',
        'title': 'Original',
        'price': 99,
        'creatorHandle': 'kasinadhsarma',
      }),
      isTrue,
    );
  });

  testWidgets('home hides remixes and shows Featured and All sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        HomeScreen(
          repository: _repo([
            {
              'id': 'p1',
              'title': 'Graphic Tee',
              'price': 499,
              'stockCount': 5,
              'featured': true,
            },
            {
              'id': 'p2',
              'title': 'Remix by @user',
              'price': 0,
              'creatorHandle': 'user',
            },
            {'id': 'p3', 'title': 'Plain Tee', 'price': 299, 'stockCount': 2},
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FEATURED PRODUCTS'), findsOneWidget);
    expect(find.text('ALL PRODUCTS'), findsOneWidget);
    expect(find.text('DESIGN'), findsNothing, reason: 'wordmark is a RichText');
    expect(find.textContaining('Remix by'), findsNothing);
    expect(find.text('Plain Tee'), findsOneWidget);
  });

  testWidgets('home shows products from the CMS', (tester) async {
    await tester.pumpWidget(
      testApp(
        HomeScreen(
          repository: _repo([
            {'id': 'p1', 'title': 'Graphic Tee', 'price': 499, 'stockCount': 5},
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Graphic Tee'), findsOneWidget);
    expect(find.text('₹499'), findsOneWidget);
  });

  testWidgets('home shows empty state', (tester) async {
    await tester.pumpWidget(testApp(HomeScreen(repository: _repo([]))));
    await tester.pumpAndSettle();
    expect(find.text('No products yet'), findsOneWidget);
  });
}
