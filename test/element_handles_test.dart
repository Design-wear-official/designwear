import 'package:designwear/models/models.dart';
import 'package:designwear/screens/studio/editor/canvas/design_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1x1 transparent PNG
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

/// The handles on a selected element (resize, rotate, delete) must react to a press anywhere on the round handle,
/// including the half that sits outside the element's box (a Flutter hit test ignores anything outside a widget's box).
void main() {
  Future<({List<DesignElement> previews, int commits, List<String> deleted})>
  pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final el = DesignElement(
      id: 'a',
      type: DesignElementType.image,
      content: _png,
      x: -60,
      y: 0,
      width: 120,
      height: 120,
      side: DesignSide.front,
    );
    final design = CustomDesign(styleId: 'crew_pocket_both').addElement(el);
    final previews = <DesignElement>[];
    final deleted = <String>[];
    var commits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: DesignCanvas(
                design: design,
                selectedElementId: 'a',
                side: DesignSide.front,
                onElementSelected: (_) {},
                onElementPreview: previews.add,
                onElementCommit: () => commits++,
                onElementDelete: deleted.add,
                onSideChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    return (previews: previews, commits: commits, deleted: deleted);
  }

  testWidgets(
    'the resize handle shrinks the element, wherever on the handle it is grabbed',
    (tester) async {
      final r = await pump(tester);
      final handle = tester.getCenter(find.byIcon(Icons.open_in_full));
      for (final grab in [
        const Offset(0, 0),
        const Offset(7, 7),
        const Offset(-7, -7),
      ]) {
        r.previews.clear();
        await tester.dragFrom(handle + grab, const Offset(-30, -30));
        await tester.pump();
        expect(r.previews, isNotEmpty, reason: 'grab at $grab moved nothing');
        expect(r.previews.last.width!, lessThan(120), reason: 'grab at $grab');
      }
    },
  );

  testWidgets('the rotate handle rotates and the delete handle deletes', (
    tester,
  ) async {
    final r = await pump(tester);
    await tester.dragFrom(
      tester.getCenter(find.byIcon(Icons.rotate_right)),
      const Offset(40, 10),
    );
    await tester.pump();
    expect(
      r.previews.any((e) => e.rotation != 0),
      isTrue,
      reason: 'the rotate handle did not react',
    );
    await tester.tapAt(
      tester.getCenter(find.byIcon(Icons.close)) + const Offset(-6, -6),
    );
    await tester.pump();
    expect(r.deleted, [
      'a',
    ], reason: 'the delete handle did not react on its outer half');
  });

  testWidgets(
    'a slow drag leaves the centre line, and stops at the print area edge without jumping back',
    (tester) async {
      final r = await pump(tester);
      final body = find.byType(DesignCanvas);
      final start = tester.getCenter(body) + const Offset(-60, 0);
      // Slow, 1 px at a time, to the right across the centre line: the old code held the element on the line.
      final g = await tester.startGesture(start);
      for (var i = 0; i < 60; i++) {
        await g.moveBy(const Offset(1, 0));
        await tester.pump();
      }
      await g.up();
      await tester.pump();
      expect(
        r.previews.last.x,
        greaterThan(-35),
        reason:
            'the element should leave the centre line and follow the pointer',
      );
      // A long drag far past the right edge ends at the edge, not beyond it.
      final g2 = await tester.startGesture(start + const Offset(60, 0));
      await g2.moveBy(const Offset(400, 0));
      await tester.pump();
      await g2.up();
      await tester.pump();
      expect(r.previews.last.x + 120, lessThanOrEqualTo(130 + 0.5));
    },
  );
}
