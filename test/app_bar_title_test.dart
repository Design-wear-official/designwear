import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:designwear/theme/app_theme.dart';

void main() {
  // The app bar title (Profile, Settings, ...) was white on both themes, so it
  // vanished on the light theme's off-white bar.
  for (final brightness in Brightness.values) {
    testWidgets('app bar title is readable on the $brightness theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(brightness),
          home: Scaffold(appBar: AppBar(title: const Text('Profile'))),
        ),
      );
      final title = tester.widget<RichText>(
        find
            .descendant(
              of: find.byType(AppBar),
              matching: find.byType(RichText),
            )
            .first,
      );
      final text = title.text.style!.color!;
      if (brightness == Brightness.light) {
        expect(text.computeLuminance(), lessThan(0.2));
      } else {
        expect(text.computeLuminance(), greaterThan(0.8));
      }
    });
  }
}
