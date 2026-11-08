import 'dart:convert';

import 'package:designwear/models/design.dart' show CommunityDesign;
import 'package:designwear/models/models.dart';
import 'package:designwear/screens/studio/community/design_detail_screen.dart';
import 'package:designwear/screens/studio/editor/canvas/design_canvas.dart';
import 'package:designwear/screens/studio/editor/canvas/garment_registry.dart';
import 'package:designwear/screens/studio/editor/support/design_studio_constants.dart';
import 'package:designwear/screens/studio/editor/support/design_studio_utils.dart';
import 'package:designwear/screens/studio/editor/support/protected_names.dart';
import 'package:designwear/services/ai/ai_agent_service.dart';
import 'package:designwear/services/ai/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Ai extends UnconfiguredAiService {
  @override
  bool get tryOnEnabled => true;
  @override
  Future<DesignSides> designSides(
    String prompt, {
    List<List<int>> images = const [],
  }) async => DesignSides(
    images: {
      for (final s in ['front', 'back', 'left', 'right']) s: base64Encode([1]),
    },
  );
}

void main() {
  setUp(GarmentRegistry.reset);
  tearDown(GarmentRegistry.reset);

  group('the print area', () {
    test('a whole element is kept inside it, not just its corner', () {
      final b = DesignStudioConstants.clampBox(120, 190, 200, 240);
      expect(b.x + 200, lessThanOrEqualTo(DesignStudioConstants.printAreaMaxX));
      expect(b.y + 240, lessThanOrEqualTo(DesignStudioConstants.printAreaMaxY));
      expect(b.x, greaterThanOrEqualTo(DesignStudioConstants.printAreaMinX));
      final small = DesignStudioConstants.clampBox(0, 0, 50, 50);
      expect((small.x, small.y), (0.0, 0.0));
      final huge = DesignStudioConstants.clampBox(0, 0, 400, 400);
      expect(huge.x, DesignStudioConstants.printAreaMinX);
    });

    test(
      'the pictures the assistant places sit inside it on every side and style',
      () async {
        AiService.instance = _Ai();
        for (final style in ['crew', 'polo', 'henley']) {
          GarmentRegistry.updateFromBackend([
            Garment.fromJson({'id': 'g', 'label': 'G', 'style': style}),
          ]);
          final r = await AIAgentService().generateSideLayers(
            'x',
            style: style,
          );
          expect(r.layers.length, 4);
          for (final e in r.layers) {
            expect(
              e.x,
              greaterThanOrEqualTo(DesignStudioConstants.printAreaMinX),
            );
            expect(
              e.x + e.width!,
              lessThanOrEqualTo(DesignStudioConstants.printAreaMaxX),
            );
            expect(
              e.y,
              greaterThanOrEqualTo(DesignStudioConstants.printAreaMinY),
            );
            expect(
              e.y + e.height!,
              lessThanOrEqualTo(DesignStudioConstants.printAreaMaxY),
            );
          }
        }
      },
    );

    testWidgets('the label shows the garment\'s own print size per side', (
      tester,
    ) async {
      GarmentRegistry.updateFromBackend([
        Garment.fromJson({
          'id': 'tshirt',
          'label': 'T',
          'placements': [
            {
              'key': 'front',
              'label': 'F',
              'width': 3600,
              'height': 4800,
              'dpi': 300,
            },
            {
              'key': 'sleeve_left',
              'label': 'L',
              'width': 1200,
              'height': 1050,
              'dpi': 300,
            },
          ],
        }),
      ]);
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<void> show(DesignSide side) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DesignCanvas(
                  design: CustomDesign(),
                  selectedElementId: null,
                  side: side,
                  onElementSelected: (_) {},
                  onElementPreview: (_) {},
                  onElementCommit: () {},
                  onElementDelete: (_) {},
                  onSideChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }

      await show(DesignSide.front);
      expect(find.text('PRINT 12 × 16 in'), findsOneWidget);
      await show(DesignSide.left);
      expect(find.text('PRINT 4 × 3.5 in'), findsOneWidget);
      await show(DesignSide.back);
      expect(
        find.text('PRINT 30 × 40 cm'),
        findsOneWidget,
        reason: 'no size known: the old label',
      );
    });
  });

  group('shirt colour', () {
    test('a dark shirt keeps its folds; white is unchanged', () {
      final dark = DesignStudioUtils.shirtGain(const Color(0xFF111111));
      // Photo brightness 1.0 (lit cloth) vs 0.5 (a fold): the gap must stay visible.
      expect(dark.r * (1.0 - 0.5), greaterThan(0.06));
      // Plain multiply would give 0.067 * 0.5 = 0.03 between them.
      expect(dark.r, greaterThan(0.067 * 2));
      final white = DesignStudioUtils.shirtGain(const Color(0xFFFFFFFF));
      expect((white.r, white.g, white.b), (1.0, 1.0, 1.0));
      final navy = DesignStudioUtils.shirtGain(const Color(0xFF1A1F3C));
      expect(navy.b, greaterThan(navy.r), reason: 'still navy, not grey');
    });
  });

  group('protected names', () {
    test(
      'a trademark in the name or text is found, ordinary words are not',
      () {
        expect(protectedNameIn('AVENGERS DOOMSDAY'), 'avengers');
        expect(protectedNameIn('sp1derman'), isNotNull);
        expect(protectedNameIn('s p i d e r m a n'), isNotNull);
        expect(protectedNameIn('Café Nike'), 'nike');
        expect(protectedNameIn('storm over the city'), isNull);
        expect(
          protectedNameIn('the author'),
          isNull,
          reason: 'thor inside a word',
        );
        expect(protectedNameInDesign('My tee', ['hello', 'BATMAN']), 'batman');
        expect(protectedNameInDesign('My tee', ['hello']), isNull);
      },
    );
  });

  group('buying a published design', () {
    testWidgets('the size the creator chose is preselected', (tester) async {
      tester.view.physicalSize = const Size(900, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: DesignDetailScreen(
            design: CommunityDesign(
              id: 'd1',
              name: 'Storm',
              garment: 'tshirt',
              creatorName: 'A',
              creatorHandle: 'a',
              likeCount: 0,
              remixCount: 0,
              liked: false,
              mine: false,
              price: 499,
              designJson: {'size': 'XL'},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .value,
        'XL',
      );
    });
  });
}
