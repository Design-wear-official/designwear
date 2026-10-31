import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/widgets/agent_chat_widget.dart';
import 'package:designwear/presentation/widgets/ai_allowance_chip.dart';
import 'package:designwear/screens/account/profile_screen.dart';
import 'package:designwear/services/ai/ai_service.dart';
import 'package:designwear/services/auth/auth_service.dart';
import 'package:designwear/services/ai/ai_usage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_app.dart';

Future<AiUsageService> _usage({
  String plan = 'free',
  int limit = 3,
  int used = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  final api = ApiClient(
    'https://api.example.com',
    httpClient: MockClient(
      (_) async => http.Response(
        jsonEncode({
          'plan': plan,
          'limit': limit,
          'used': used,
          'remaining': limit - used,
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    ),
  );
  await api.setToken('t');
  final service = AiUsageService(api: api);
  await service.refresh();
  return service;
}

class _CountingAgent extends UnconfiguredAiService {
  int calls = 0;
  @override
  bool get agentEnabled => true;
  @override
  bool get tryOnEnabled => false;
  @override
  Future<({String text, Map<String, Object?>? design})> designAgent({
    required String message,
    required Map<String, Object?> design,
    required List<({bool fromUser, String text})> history,
    List<List<int>> images = const [],
  }) async {
    calls++;
    return (text: 'ok', design: null);
  }
}

Widget _chat(AiUsageService usage) => ChangeNotifierProvider.value(
  value: usage,
  child: MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          AgentChatWidget(
            currentDesign: CustomDesign(),
            onDesignUpdate: (_) {},
          ),
        ],
      ),
    ),
  ),
);

void main() {
  test('reads the allowance from the server and words it for people', () async {
    final usage = await _usage(used: 1);
    expect(usage.known, isTrue);
    expect(usage.remaining, 2);
    expect(usage.summary, '2 of 3 AI creations left today');
    expect(usage.planLabel, 'Free');
    expect(usage.exhausted, isFalse);

    final empty = await _usage(used: 3);
    expect(empty.exhausted, isTrue);
    expect(empty.summary, contains('No AI creations left'));

    final pro = await _usage(plan: 'pro', limit: 30, used: 4);
    expect(pro.planLabel, 'Pro');
    expect(pro.summary, '26 of 30 AI creations left today');

    pro.clear();
    expect(pro.known, isFalse);
    expect(pro.exhausted, isFalse, reason: 'unknown is never treated as empty');
  });

  testWidgets('the chip shows the count, and nothing before it is known', (
    tester,
  ) async {
    final known = await _usage(used: 2);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: known,
        child: const MaterialApp(home: Scaffold(body: AiAllowanceChip())),
      ),
    );
    expect(find.text('1 of 3 AI creations left today'), findsOneWidget);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: AiUsageService(),
        child: const MaterialApp(home: Scaffold(body: AiAllowanceChip())),
      ),
    );
    expect(find.byIcon(Icons.bolt), findsNothing);

    // No provider at all (a screen outside the app) must not crash.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AiAllowanceChip())),
    );
    expect(find.byIcon(Icons.bolt), findsNothing);
  });

  group('the assistant', () {
    late AiService original;
    setUp(() => original = AiService.instance);
    tearDown(() => AiService.instance = original);

    testWidgets('shows what is left and sends while there is some', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final agent = _CountingAgent();
      AiService.instance = agent;
      await tester.pumpWidget(_chat(await _usage(used: 1)));
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      expect(find.text('2 of 3 AI creations left today'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'a sun tee');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(const Duration(milliseconds: 600));
      expect(agent.calls, 1);
    });

    testWidgets('with none left it says so and does not send', (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final agent = _CountingAgent();
      AiService.instance = agent;
      await tester.pumpWidget(_chat(await _usage(used: 3)));
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      expect(find.textContaining('No AI creations left today'), findsOneWidget);
      expect(find.text('Daily AI limit reached'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'a sun tee');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        agent.calls,
        0,
        reason: 'no request is made when the day is used up',
      );
    });
  });
  testWidgets('the profile shows the plan and what is left today', (
    tester,
  ) async {
    final usage = await _usage(plan: 'pro', limit: 30, used: 4);
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService();
    await auth.register('Ada Lovelace', 'ada@example.com', 'password123');
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(const ProfileScreen(), auth: auth, aiUsage: usage),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pro plan'), findsOneWidget);
    expect(find.text('26 of 30 AI creations left today'), findsOneWidget);
    expect(find.text('Pro and Ultra'), findsOneWidget);
    expect(find.textContaining('Coming soon'), findsOneWidget);
  });
}
