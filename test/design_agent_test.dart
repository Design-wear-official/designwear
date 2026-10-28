import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/widgets/agent_chat_widget.dart';
import 'package:designwear/services/ai/ai_agent_service.dart';
import 'package:designwear/services/ai/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for the server: it "designs" by returning an edited design.
class _FakeAgent extends UnconfiguredAiService {
  _FakeAgent({this.enabled = true, this.reply});
  final bool enabled;
  final ({String text, Map<String, Object?>? design}) Function(String message)?
  reply;
  final calls =
      <({String message, Map<String, Object?> design, int historyLength})>[];

  @override
  bool get agentEnabled => enabled;

  @override
  bool get tryOnEnabled => false;

  @override
  Future<({String text, Map<String, Object?>? design})> designAgent({
    required String message,
    required Map<String, Object?> design,
    required List<({bool fromUser, String text})> history,
    List<List<int>> images = const [],
  }) async {
    calls.add((
      message: message,
      design: design,
      historyLength: history.length,
    ));
    return reply!(message);
  }
}

({String text, Map<String, Object?>? design}) _designs(String message) => (
  text: 'Done: $message',
  design: {
    'baseColor': '0xFF1A237E',
    'elements': [
      {
        'id': 'el_1',
        'type': 'text',
        'content': 'SUNRISE',
        'x': 0,
        'y': 0,
        'size': 32,
        'color': '0xFFFFFFFF',
      },
    ],
  },
);

void main() {
  late AiService original;
  setUp(() => original = AiService.instance);
  tearDown(() => AiService.instance = original);

  group('the design agent is the only chat bot', () {
    test('turns what the user asks for into a changed design, and remembers the conversation', () async {
      final fake = _FakeAgent(reply: _designs);
      AiService.instance = fake;
      final agent = AIAgentService();
      final start = CustomDesign(baseColor: '0xFFFFFFFF');

      final first = await agent.sendMessage(
        'navy shirt that says SUNRISE',
        start,
      );
      expect(first.text, 'Done: navy shirt that says SUNRISE');
      expect(first.updatedDesign!.baseColor, '0xFF1A237E');
      expect(first.updatedDesign!.elements.single.content, 'SUNRISE');
      // The model is given the design it is editing.
      expect(fake.calls.single.design['baseColor'], '0xFFFFFFFF');
      expect(fake.calls.single.historyLength, 0);

      await agent.sendMessage('make it bigger', first.updatedDesign!);
      expect(
        fake.calls.last.historyLength,
        2,
        reason: 'the first exchange is sent as context',
      );
      expect(
        (fake.calls.last.design['elements'] as List).single['content'],
        'SUNRISE',
      );
    });

    test('a reply with no design change is just a message', () async {
      AiService.instance = _FakeAgent(
        reply: (m) => (text: 'Which colour do you like?', design: null),
      );
      final r = await AIAgentService().sendMessage('hmm', CustomDesign());
      expect(r.text, 'Which colour do you like?');
      expect(r.updatedDesign, isNull);
    });

    test(
      'says so plainly when the assistant is not connected, and never throws',
      () async {
        AiService.instance = _FakeAgent(enabled: false, reply: _designs);
        final r = await AIAgentService().sendMessage(
          'anything',
          CustomDesign(),
        );
        expect(r.updatedDesign, isNull);
        expect(r.text, contains('not connected'));
        AiService.instance = const UnconfiguredAiService();
        expect(
          (await AIAgentService().sendMessage(
            'x',
            CustomDesign(),
          )).updatedDesign,
          isNull,
        );
      },
    );

    test('failures from the service become a friendly message', () async {
      AiService.instance = _FakeAgent(
        reply: (m) => throw const AiFailure('The assistant is busy.'),
      );
      final r = await AIAgentService().sendMessage('x', CustomDesign());
      expect(r.text, 'The assistant is busy.');
      expect(r.updatedDesign, isNull);
    });

    testWidgets('in the studio: type a request, send, and the design changes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AiService.instance = _FakeAgent(reply: _designs);
      CustomDesign? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AgentChatWidget(
                  currentDesign: CustomDesign(),
                  onDesignUpdate: (d) => applied = d,
                  bottomOffset: 20,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'navy shirt that says SUNRISE',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(applied, isNotNull, reason: 'the studio is handed the new design');
      expect(applied!.elements.single.content, 'SUNRISE');
      final shown = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((r) => r.text.toPlainText());
      expect(
        shown,
        contains('Done: navy shirt that says SUNRISE'),
        reason: "the bot's reply is shown in the chat",
      );
      expect(find.text('DesignBot AI'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
