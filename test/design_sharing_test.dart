import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/models/design.dart';
import 'package:designwear/screens/studio/community/design_detail_screen.dart';
import 'package:designwear/screens/studio/community/share_design_sheet.dart';
import 'package:designwear/screens/studio/community/share_links.dart';
import 'package:designwear/services/community/community_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_app.dart';

const _token = 'abcdefghijklmnopqrstuv';

/// A stand-in for the API's sharing routes, with the state the owner would have.
class _Fake {
  Map<String, Object?> state = {
    'visibility': 'private',
    'allowRemix': false,
    'link': {'enabled': false, 'token': null},
    'people': <Object?>[],
  };
  final calls = <String>[];

  CommunityService service() => CommunityService(
    ApiClient(
      'https://api.example.com',
      httpClient: MockClient((req) async {
        calls.add(
          '${req.method} ${req.url.path}${req.url.hasQuery ? '?${req.url.query}' : ''}',
        );
        if (req.method == 'PUT') {
          final b = jsonDecode(req.body) as Map<String, Object?>;
          if (b['visibility'] != null) state['visibility'] = b['visibility'];
          if (b['link'] == true) {
            state['link'] = {'enabled': true, 'token': _token};
          }
          if (b['link'] == false) {
            state['link'] = {'enabled': false, 'token': null};
          }
          if (b['allowRemix'] != null) state['allowRemix'] = b['allowRemix'];
          final notFound = <String>[];
          for (final e in (b['addEmails'] as List? ?? const [])) {
            if ('$e'.startsWith('bob')) {
              (state['people'] as List).add({'userId': 'u_bob', 'name': 'Bob'});
              if (state['visibility'] == 'private') {
                state['visibility'] = 'shared';
              }
            } else {
              notFound.add('$e');
            }
          }
          // The API says "shared" while a link or a person has access, "private" otherwise, unless it is public.
          if (state['visibility'] != 'public') {
            final linkOn = (state['link'] as Map)['enabled'] == true;
            state['visibility'] = linkOn || (state['people'] as List).isNotEmpty
                ? 'shared'
                : 'private';
          }
          return http.Response(
            jsonEncode({...state, 'notFound': notFound}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(state),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    ),
  );
}

Future<void> _open(WidgetTester tester, _Fake fake) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    testApp(
      community: fake.service(),
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showShareDesignSheet(
                context,
                designId: 'd_1',
                designName: 'Storm',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('share links', () {
    test(
      'a private link and a public link round-trip, and a try-on link says so',
      () {
        final detail = detailLink('d_1', token: _token);
        expect(detail, contains('?share=d_1.$_token'));
        final r = parseShareRequest(detail)!;
        expect([r.id, r.token, r.tryOn], ['d_1', _token, false]);
        final t = parseShareRequest(tryOnLink('d_1', token: _token))!;
        expect([t.id, t.token, t.tryOn], ['d_1', _token, true]);
        final pub = parseShareRequest(tryOnLink('d_1'))!;
        expect([pub.id, pub.token, pub.tryOn], ['d_1', null, true]);
        final code = parseShareRequest('  d_1.$_token ')!;
        expect([code.id, code.token], ['d_1', _token]);
        expect(parseShareRequest('hello'), isNull);
        expect(parseShareRequest('https://x.test/?share=notadesign'), isNull);
      },
    );
  });

  group('the share sheet', () {
    testWidgets(
      'private by default; the link switch shows a details link and a try-on link; people are added by email',
      (tester) async {
        final fake = _Fake();
        await _open(tester, fake);
        expect(find.textContaining('Private: only you'), findsOneWidget);
        expect(find.text('Details link'), findsNothing);

        await tester.tap(find.text('Anyone with the private link'));
        await tester.pumpAndSettle();
        expect(find.text('Details link'), findsOneWidget);
        expect(find.text('Try-on link'), findsOneWidget);
        expect(
          find.textContaining('Shared: only the people and links'),
          findsOneWidget,
        );

        await tester.enterText(find.byType(TextField), 'bob@example.com');
        await tester.tap(find.text('Share').last);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(InputChip, 'Bob'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'nobody@example.com');
        await tester.tap(find.text('Share').last);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('No DesignWear account for nobody@example.com'),
          findsOneWidget,
        );

        await tester.tap(find.text('Let them order or copy it'));
        await tester.pumpAndSettle();
        expect(fake.state['allowRemix'], true);
      },
    );

    testWidgets(
      'making it public shows links without a token; turning the link off hides them',
      (tester) async {
        final fake = _Fake();
        await _open(tester, fake);
        await tester.tap(find.text('Public in the community'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Public: anyone can find it'),
          findsOneWidget,
        );
        expect(find.text('Try-on link'), findsOneWidget);
        await tester.tap(find.text('Public in the community'));
        await tester.pumpAndSettle();
        expect(find.text('Try-on link'), findsNothing);
      },
    );
  });

  group('a design shared with me', () {
    CommunityDesign shared({bool allowRemix = false}) => CommunityDesign(
      id: 'd_1',
      name: 'Storm',
      garment: 'T-Shirt',
      creatorName: 'Ada',
      creatorHandle: 'ada',
      likeCount: 0,
      remixCount: 0,
      liked: false,
      mine: false,
      price: 499,
      visibility: 'shared',
      allowRemix: allowRemix,
    );

    testWidgets(
      'can be looked at and tried on, but not ordered or copied unless the owner allows it',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(testApp(DesignDetailScreen(design: shared())));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Shared with you'), findsOneWidget);
        expect(find.byTooltip('Try it on'), findsOneWidget);
        expect(
          find.byTooltip('Share'),
          findsNothing,
          reason: 'only the owner shares',
        );
        expect(find.textContaining('Add to cart'), findsNothing);
        expect(find.text('Remix this design'), findsNothing);
        expect(
          find.textContaining('Its owner has not allowed copies'),
          findsOneWidget,
        );

        await tester.pumpWidget(
          testApp(
            DesignDetailScreen(
              key: UniqueKey(),
              design: shared(allowRemix: true),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('Add to cart'), findsOneWidget);
        expect(find.text('Remix this design'), findsOneWidget);
      },
    );
  });
}
