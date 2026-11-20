import 'package:designwear/models/models.dart'
    show CustomDesign, DesignElement, DesignElementType;
import 'package:designwear/screens/studio/editor/canvas/design_canvas.dart';
import 'package:designwear/screens/studio/editor/design_studio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'arrow buttons move the selected element exactly, hold repeats, step 10 moves further, and smaller shrinks',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final design = CustomDesign(
        name: 'N',
        elements: [
          DesignElement(
            id: 't1',
            type: DesignElementType.text,
            content: 'NUDGE',
            size: 30,
            x: -90,
            y: 0,
          ),
        ],
      );
      await tester.pumpWidget(
        testApp(DesignStudioScreen(initialDesign: design)),
      );
      await tester.pump(const Duration(seconds: 1));
      final text = find.descendant(
        of: find.byType(DesignCanvas),
        matching: find.text('NUDGE', findRichText: true),
      );
      await tester.tap(text.first);
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byIcon(Icons.arrow_forward),
        findsOneWidget,
        reason: 'the arrow buttons show when an element is selected',
      );

      Offset at() => tester.getTopLeft(text.first);
      final start = at();

      // One press = one unit.
      var g = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.arrow_forward)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await g.up();
      await tester.pump();
      final perUnit = (at() - start).dx; // pixels on screen for one canvas unit (the canvas is drawn larger than 1:1)
      expect(perUnit, inInclusiveRange(0.9, 3));

      // Holding repeats.
      final before = at();
      g = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.arrow_forward)),
      );
      await tester.pump(const Duration(milliseconds: 800));
      await g.up();
      await tester.pump();
      expect(
        (at() - before).dx,
        greaterThan(perUnit * 4),
        reason: 'held for a moment: several steps',
      );

      // Step 10 moves ten at a time.
      await tester.tap(find.textContaining('Step 1'));
      await tester.pump();
      expect(find.text('Step 10'), findsOneWidget);
      final before10 = at();
      g = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.arrow_downward)),
      );
      await g.up();
      await tester.pump();
      expect((at() - before10).dy, closeTo(10 * perUnit, 1));

      // Smaller makes the text smaller.
      final width = tester.getSize(text.first).width;
      g = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.remove)),
      );
      await tester.pump(const Duration(milliseconds: 800));
      await g.up();
      await tester.pump();
      expect(tester.getSize(text.first).width, lessThan(width));
    },
  );

  testWidgets('the placement row fits on a phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final design = CustomDesign(
      name: 'P',
      elements: [
        DesignElement(
          id: 't1',
          type: DesignElementType.text,
          content: 'PHONE',
          size: 30,
          x: -90,
          y: 0,
        ),
      ],
    );
    await tester.pumpWidget(testApp(DesignStudioScreen(initialDesign: design)));
    await tester.pump(const Duration(seconds: 1));
    final text = find.descendant(
      of: find.byType(DesignCanvas),
      matching: find.text('PHONE', findRichText: true),
    );
    await tester.tap(text.first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
