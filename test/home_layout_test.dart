import 'dart:convert';

import 'package:designwear/cms/cms_config.dart';
import 'package:designwear/cms/cms_service.dart';
import 'package:designwear/data/product_repository.dart';
import 'package:designwear/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_app.dart';

ProductRepository _repo() => ProductRepository(
  cms: CmsService(
    const CmsConfig(
      baseUrl: 'https://cms.example.com',
      connectionId: 'c',
      viewerToken: 't',
    ),
    httpClient: MockClient(
      (_) async => http.Response(
        jsonEncode({
          'data': [
            for (var i = 0; i < 8; i++)
              {
                'id': 'p$i',
                'title': 'Tee $i',
                'price': 499,
                'stockCount': 5,
                'featured': i < 2,
              },
          ],
          'nextCursor': null,
          'limit': 40,
          'notes': [],
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    ),
  ),
);

void main() {
  alignmentTests();
  Future<void> open(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(HomeScreen(repository: _repo())));
    await tester.pumpAndSettle();
  }

  Rect barRect(WidgetTester tester) => tester.getRect(
    find
        .ancestor(
          of: find.byType(TextField).first,
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );

  testWidgets(
    'wide window: search bar flexes inside a 1440 container with the filter button',
    (tester) async {
      await open(tester, const Size(1920, 1080));
      expect(tester.takeException(), isNull);

      final bar = barRect(tester);
      expect(bar.height, 40);
      expect(
        bar.width,
        greaterThan(500),
        reason: 'it takes the room between brand and actions',
      );
      // 1440px container with 92px side padding, centred in a 1920px window.
      expect(bar.left, greaterThanOrEqualTo((1920 - 1440) / 2 + 92));
      expect(bar.right, lessThanOrEqualTo((1920 + 1440) / 2 - 92));

      expect(find.text('Create'), findsOneWidget);
      expect(find.byTooltip('Filter search'), findsOneWidget);
      // Cart and notifications are in the profile menu, not the header.
      expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
      expect(find.byIcon(Icons.notifications_none), findsNothing);
    },
  );

  testWidgets(
    'phone: compact header, no filter button, Create is a plus icon',
    (tester) async {
      await open(tester, const Size(390, 844));
      expect(tester.takeException(), isNull);
      final bar = barRect(tester);
      expect(bar.height, 40);
      expect(bar.width, greaterThan(40));
      expect(bar.right, lessThan(390));
      expect(find.byTooltip('Filter search'), findsNothing);
      expect(find.text('Create'), findsNothing);
      expect(find.byTooltip('Create a design'), findsOneWidget);
    },
  );

  testWidgets(
    'typing shows suggested searches; picking one fills the field; Escape clears',
    (tester) async {
      await open(tester, const Size(1400, 900));
      final field = find.byType(TextField).first;
      expect(find.text('SUGGESTED SEARCHES'), findsNothing);

      await tester.tap(field);
      await tester.enterText(field, 'tee 1');
      await tester.pump();
      expect(find.text('SUGGESTED SEARCHES'), findsOneWidget);
      expect(find.text('Tee 1'), findsWidgets);

      await tester.enterText(field, 'zzzz-no-match');
      await tester.pump();
      expect(
        find.text('SUGGESTED SEARCHES'),
        findsNothing,
        reason: 'nothing to suggest',
      );

      await tester.enterText(field, 'tee');
      await tester.pump();
      expect(find.text('SUGGESTED SEARCHES'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(find.text('SUGGESTED SEARCHES'), findsNothing);
    },
  );

  testWidgets('search bar has a clear button only while there is text', (
    tester,
  ) async {
    await open(tester, const Size(1400, 900));
    expect(find.byTooltip('Clear search'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'hoodie');
    await tester.pump();
    expect(find.byTooltip('Clear search'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.byTooltip('Clear search'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
  });
}

void alignmentTests() {
  Future<void> open(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(HomeScreen(repository: _repo())));
    await tester.pumpAndSettle();
  }

  for (final size in const [Size(1920, 1080), Size(390, 844)]) {
    testWidgets(
      'header items are the same height and share one centre line at ${size.width.toInt()}px',
      (tester) async {
        await open(tester, size);
        final bar = tester.getRect(
          find
              .ancestor(
                of: find.byType(TextField).first,
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        final field = tester.getRect(find.byType(TextField).first);
        final profile = tester.getRect(
          find
              .ancestor(
                of: find.byIcon(Icons.person_outline),
                matching: find.byType(Container),
              )
              .first,
        );
        final searchIcon = tester.getRect(find.byIcon(Icons.search).first);

        // The text field fills the whole bar and centres its text, so the
        // placeholder shares the icons' centre line in the browser too.
        expect(
          field.height,
          bar.height - 2,
          reason: 'the bar minus its 1px border',
        );
        expect(profile.size, const Size(40, 40));
        // Everything sits on the bar's centre line.
        for (final r in [field, profile, searchIcon]) {
          expect((r.center.dy - bar.center.dy).abs(), lessThan(1.0));
        }
      },
    );
  }
}
