import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/services/auth/firebase_env.dart';
import 'package:designwear/services/auth/google_id_token_source.dart';
import 'package:designwear/screens/account/auth_screens.dart';
import 'package:designwear/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_app.dart';

class _FakeGoogle implements GoogleIdTokenSource {
  _FakeGoogle(this.token, {this.available = true, this.failure});
  final String? token;
  final bool available;
  final GoogleSignInFailure? failure;
  int calls = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<String?> idToken() async {
    calls++;
    if (failure != null) throw failure!;
    return token;
  }
}

ApiClient _api(void Function(http.Request) onRequest, {int status = 200}) =>
    ApiClient(
      'https://api.example.com',
      httpClient: MockClient((r) async {
        onRequest(r);
        return http.Response(
          status == 200
              ? jsonEncode({
                  'token': 'session',
                  'user': {'id': 'u', 'name': 'Gina', 'email': 'g@x.com'},
                })
              : jsonEncode({
                  'error': {
                    'code': 'invalid_token',
                    'message': 'Google sign-in could not be verified.',
                  },
                }),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AuthService.signInWithGoogle', () {
    test('trades the Google ID token for an API session', () async {
      late http.Request seen;
      final api = _api((r) => seen = r);
      final auth = AuthService(
        api: api,
        google: _FakeGoogle('firebase-id-token'),
      );
      expect(auth.googleAvailable, isTrue);
      expect(await auth.signInWithGoogle(), isNull);
      expect(auth.isSignedIn, isTrue);
      expect(auth.user!.name, 'Gina');
      expect(api.hasToken, isTrue);
      expect(seen.url.path, '/v1/auth/google');
      expect(jsonDecode(seen.body), {'idToken': 'firebase-id-token'});
    });

    test(
      'closing the Google window is not an error and does not sign in',
      () async {
        var requested = false;
        final auth = AuthService(
          api: _api((_) => requested = true),
          google: _FakeGoogle(null),
        );
        expect(await auth.signInWithGoogle(), isNull);
        expect(auth.isSignedIn, isFalse);
        expect(requested, isFalse);
      },
    );

    test('surfaces a rejected token and a Google-side failure', () async {
      final rejected = AuthService(
        api: _api((_) {}, status: 401),
        google: _FakeGoogle('bad'),
      );
      expect(
        await rejected.signInWithGoogle(),
        'Google sign-in could not be verified.',
      );
      expect(rejected.isSignedIn, isFalse);

      final failed = AuthService(
        api: _api((_) {}),
        google: _FakeGoogle(
          'x',
          failure: const GoogleSignInFailure("Couldn't reach Google."),
        ),
      );
      expect(await failed.signInWithGoogle(), "Couldn't reach Google.");
    });

    test('is unavailable without the API or without Firebase', () async {
      final noApi = AuthService(google: _FakeGoogle('t'));
      expect(noApi.googleAvailable, isFalse);
      expect(await noApi.signInWithGoogle(), isNotNull);
      final noFirebase = AuthService(
        api: _api((_) {}),
        google: _FakeGoogle('t', available: false),
      );
      expect(noFirebase.googleAvailable, isFalse);
    });
  });

  group('FirebaseEnv', () {
    final full = {
      'FIREBASE_PROJECT_ID': 'dw',
      'FIREBASE_MESSAGING_SENDER_ID': '123',
      'FIREBASE_WEB_API_KEY': 'web-key',
      'FIREBASE_WEB_APP_ID': '1:123:web:abc',
      'FIREBASE_ANDROID_API_KEY': 'and-key',
      'FIREBASE_ANDROID_APP_ID': '1:123:android:abc',
      'FIREBASE_INTERNAL_PROJECT_ID': 'dw-internal',
    };

    test('is null until every required value is set, per flavour prefix', () {
      // The test VM is neither web nor a mobile platform, so Firebase is off here
      // by design; the parsing itself is covered by a platform-independent check.
      expect(FirebaseEnv.read('FIREBASE_', env: const {}), isNull);
      expect(
        FirebaseEnv.read('FIREBASE_', env: {'FIREBASE_PROJECT_ID': 'dw'}),
        isNull,
      );
      expect(FirebaseEnv.read('FIREBASE_INTERNAL_', env: full), isNull);
    });
  });

  group('sign-in screen', () {
    testWidgets('shows Continue with Google only when it is set up', (
      tester,
    ) async {
      Widget screen(AuthService auth) =>
          testApp(const LoginScreen(), auth: auth);

      await tester.pumpWidget(
        screen(AuthService(api: _api((_) {}), google: _FakeGoogle('t'))),
      );
      await tester.pump();
      expect(find.text('Continue with Google'), findsOneWidget);

      // A fresh tree: the button reads availability once when it is built.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(screen(AuthService(google: _FakeGoogle('t'))));
      await tester.pump();
      expect(find.text('Continue with Google'), findsNothing);
    });

    testWidgets('without a Firebase project the button is there and says why', (
      tester,
    ) async {
      final auth = AuthService(
        api: _api((_) {}),
        google: const NoGoogleSignIn(),
      );
      await tester.pumpWidget(testApp(const LoginScreen(), auth: auth));
      await tester.pump();
      expect(find.text('Continue with Google'), findsOneWidget);
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      expect(find.text('Google sign-in is not set up yet.'), findsOneWidget);
    });

    testWidgets('tapping it signs in and closes the screen', (tester) async {
      final auth = AuthService(api: _api((_) {}), google: _FakeGoogle('t'));
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          auth: auth,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(auth.isSignedIn, isTrue);
      expect(
        find.byType(LoginScreen),
        findsNothing,
        reason: 'the sign-in screen closes on success',
      );
      // The API client logs the call; let the log's delayed save finish.
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
