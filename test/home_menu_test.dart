import 'dart:convert';

import 'package:designwear/cms/cms_config.dart';
import 'package:designwear/cms/cms_service.dart';
import 'package:designwear/data/product_repository.dart';
import 'package:designwear/screens/catalog/search_screen.dart';
import 'package:designwear/screens/home/home_screen.dart';
import 'package:flutter/gestures.dart';
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
            {'id': 'p1', 'title': 'Tee', 'price': 499, 'stockCount': 5},
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
  Future<void> open(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(HomeScreen(repository: _repo())));
    await tester.pumpAndSettle();
  }

  Finder avatar() => find.byIcon(Icons.person_outline).first;

  testWidgets('hovering the profile icon shows the menu; leaving hides it', (
    tester,
  ) async {
    await open(tester, const Size(1200, 900));
    expect(find.text('Settings'), findsNothing);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(avatar()));
    await tester.pumpAndSettle();

    for (final label in const [
      'New design',
      'Search designs',
      'Cart',
      'Sign in', // signed out, so profile is the sign-in page
      'Settings',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }

    await mouse.moveTo(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets(
    'on a touch screen a tap opens the menu and an entry opens its page',
    (tester) async {
      await open(tester, const Size(390, 844));

      await tester.tap(avatar());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    },
  );

  testWidgets('"Search designs" opens the search page', (tester) async {
    await open(tester, const Size(390, 844));
    await tester.tap(avatar());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search designs'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('Ctrl+K focuses the search field', (tester) async {
    await open(tester, const Size(1200, 900));
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.focusNode!.hasFocus, isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(field.focusNode!.hasFocus, isTrue);
  });
}
