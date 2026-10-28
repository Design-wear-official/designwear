import 'package:designwear/screens/account/profile_screen.dart';
import 'package:designwear/screens/settings/settings_screen.dart';
import 'package:designwear/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_app.dart';

Future<AuthService> signedIn() async {
  SharedPreferences.setMockInitialValues({});
  final auth = AuthService();
  await auth.register('Ada Lovelace', 'ada@example.com', 'password123');
  return auth;
}

void main() {
  testWidgets('profile: grouped cards, and a centred column on desktop', (
    tester,
  ) async {
    final auth = await signedIn();
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp(const ProfileScreen(), auth: auth));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    for (final label in [
      'SHOPPING',
      'DESIGNS',
      'My orders',
      'Shipping addresses',
      'Payment methods',
      'Community designs',
      'Saved designs',
      'Settings',
      'Sign out',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    final row = tester.getRect(find.text('My orders'));
    expect(row.left, greaterThan(300), reason: 'not stuck to the left edge');
    expect(row.right, lessThan(1140), reason: 'inside the 720 px column');
  });

  testWidgets('profile on a phone fits without overflow', (tester) async {
    final auth = await signedIn();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp(const ProfileScreen(), auth: auth));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('profile when signed out offers sign in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(testApp(const ProfileScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('My orders'), findsNothing);
  });

  testWidgets('settings: theme switch, sections, and no server address leak', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    for (final size in [const Size(1440, 900), const Size(390, 844)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(testApp(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size');
      for (final label in ['APPEARANCE', 'CONNECTION', 'SUPPORT', 'ABOUT']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('api.example.com'), findsOneWidget, reason: 'host only');
    }
    addTearDown(tester.view.reset);
  });
}
