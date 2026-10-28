import 'dart:io';

import 'package:designwear/presentation/widgets/designwear_logo.dart';
import 'package:designwear/screens/account/auth_screens.dart';
import 'package:designwear/screens/errors/error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  group('app identity', () {
    test('every platform uses com.vishwamai.designwear and none still say com.example', () {
      expect(
        read('android/app/build.gradle.kts'),
        contains('namespace = "com.vishwamai.designwear"'),
      );
      expect(
        read('android/app/build.gradle.kts'),
        contains('applicationId = "com.vishwamai.designwear"'),
      );
      expect(
        read('android/app/build.gradle.kts'),
        contains('applicationId = "com.vishwamai.designwear.internal"'),
      );
      expect(
        File(
          'android/app/src/main/kotlin/com/vishwamai/designwear/MainActivity.kt',
        ).readAsStringSync(),
        contains('package com.vishwamai.designwear'),
      );
      expect(
        Directory('android/app/src/main/kotlin/com/example').existsSync(),
        isFalse,
      );
      expect(
        read('ios/Runner.xcodeproj/project.pbxproj'),
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.vishwamai.designwear;'),
      );
      expect(
        read('macos/Runner/Configs/AppInfo.xcconfig'),
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.vishwamai.designwear'),
      );
      expect(
        read('linux/CMakeLists.txt'),
        contains('APPLICATION_ID "com.vishwamai.designwear"'),
      );
      for (final f in [
        'android/app/build.gradle.kts',
        'ios/Runner.xcodeproj/project.pbxproj',
        'macos/Runner.xcodeproj/project.pbxproj',
        'macos/Runner/Configs/AppInfo.xcconfig',
        'linux/CMakeLists.txt',
        'windows/runner/Runner.rc',
      ]) {
        expect(read(f), isNot(contains('com.example')), reason: f);
      }
    });

    test('the app is called DesignWear (and the internal build says so)', () {
      expect(
        read('android/app/src/main/AndroidManifest.xml'),
        contains('android:label="@string/app_name"'),
      );
      expect(
        read('android/app/build.gradle.kts'),
        contains('"app_name", "DesignWear"'),
      );
      expect(
        read('android/app/build.gradle.kts'),
        contains('"app_name", "DesignWear (internal)"'),
      );
      expect(read('web/index.html'), contains('<title>DesignWear</title>'));
      expect(read('web/manifest.json'), contains('"name": "DesignWear"'));
      expect(
        read('ios/Runner/Info.plist'),
        contains('<string>DesignWear</string>'),
      );
    });
  });

  group('original logo', () {
    test('icon artwork exists for every platform', () {
      for (final f in [
        'assets/images/app_icon.png',
        'assets/images/app_icon_foreground.png',
        'assets/images/logo.png',
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
        'web/icons/Icon-512.png',
        'web/icons/Icon-maskable-512.png',
        'web/favicon.png',
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png',
      ]) {
        expect(File(f).existsSync(), isTrue, reason: f);
        expect(
          File(f).lengthSync(),
          greaterThan(500),
          reason: '$f is not an empty placeholder',
        );
      }
    });

    testWidgets('the logo widget renders the asset at the requested size', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: DesignWearLogo(size: 80))),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/app_icon.png',
      );
      expect(tester.getSize(find.byType(DesignWearLogo)), const Size(80, 80));
      expect(find.bySemanticsLabel('DesignWear logo'), findsOneWidget);
    });

    testWidgets('sign-in and the 404 page show the logo', (tester) async {
      await tester.pumpWidget(testApp(const LoginScreen()));
      await tester.pump();
      expect(find.byType(DesignWearLogo), findsOneWidget);
      await tester.pumpWidget(testApp(const ErrorScreen.notFound()));
      await tester.pump();
      expect(find.byType(DesignWearLogo), findsOneWidget);
    });
  });
}
