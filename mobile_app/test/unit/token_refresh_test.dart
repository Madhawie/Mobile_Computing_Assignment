import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:little_bloom/core/auth/auth_controller.dart';
import 'package:little_bloom/core/auth/secure_store.dart';
import 'package:little_bloom/core/constants/app_language.dart';
import 'package:little_bloom/core/network/api_client.dart';
import 'package:little_bloom/core/network/api_exception.dart';

import '../helpers/fake_auth_api.dart';

/// JWT handling against the .NET rules: 12 h access token, 30 day refresh
/// token that works only once (rotation).
void main() {
  group('expired access token (12 h)', () {
    late List<String> tokensSeen;
    late int calls;
    ApiClient client({required Future<bool> Function() refresh, String code = 'TOKEN_EXPIRED'}) {
      var token = 'old';
      calls = 0;
      tokensSeen = [];
      final api = ApiClient(
        baseUrl: 'http://test',
        tokenProvider: () => token,
        client: MockClient((req) async {
          calls++;
          tokensSeen.add(req.headers['Authorization']!);
          if (req.headers['Authorization'] == 'Bearer old') {
            return http.Response(jsonEncode({'status': 401, 'code': code}), 401);
          }
          return http.Response(jsonEncode({'changes': [], 'cursor': 0, 'hasMore': false}), 200);
        }),
      );
      api.onTokenExpired = () async {
        final ok = await refresh();
        if (ok) token = 'new';
        return ok;
      };
      return api;
    }

    test('refreshes once and sends the same request again', () async {
      final api = client(refresh: () async => true);
      await api.pull(since: 0);
      expect(tokensSeen, ['Bearer old', 'Bearer new']);
    });

    test('refresh refused: the 401 reaches the caller', () async {
      final api = client(refresh: () async => false);
      await expectLater(api.pull(since: 0),
          throwsA(isA<HttpFailure>().having((f) => f.code, 'code', 'TOKEN_EXPIRED')));
      expect(calls, 1);
    });

    test('401 UNAUTHORIZED (not expired) is not refreshed', () async {
      var asked = false;
      final api = client(refresh: () async => asked = true, code: 'UNAUTHORIZED');
      await expectLater(api.pull(since: 0), throwsA(isA<HttpFailure>()));
      expect(asked, isFalse);
    });
  });

  group('AuthController.refreshSession', () {
    late FakeAuthServer server;
    late MemorySecureStore secure;
    late AuthController auth;

    setUp(() async {
      server = FakeAuthServer();
      secure = MemorySecureStore();
      auth = makeAuth(server: server, secure: secure);
      await auth.setLanguage(AppLanguage.english);
      auth.choosePath(SignInPath.staff);
      await auth.requestCode('+94700000002');
      await auth.verifyCode(fakeCode);
      await auth.setPin('2580');
    });

    test('saves the new (rotated) tokens and stays unlocked', () async {
      final before = auth.session!.refreshToken;
      expect(await auth.refreshSession(), isTrue);
      expect(auth.session!.refreshToken, isNot(before));
      expect(secure.values['session'], contains(auth.session!.refreshToken));
      expect((auth.ready, auth.hasPin), (true, true));
    });

    test('two at once share ONE refresh (a second would use a spent token)', () async {
      final results = await Future.wait([auth.refreshSession(), auth.refreshSession(), auth.refreshSession()]);
      expect(results, [true, true, true]);
      expect(server.refreshCalls, 1);
      expect(await auth.refreshSession(), isTrue); // the saved new token works next time
      expect(server.refreshCalls, 2);
    });

    test('refresh token refused: signed out (records stay on the phone)', () async {
      server.revokeAll = true;
      expect(await auth.refreshSession(), isFalse);
      expect((auth.signedIn, auth.hasPin), (false, false));
    });

    test('no signal: keeps the session for later', () async {
      server.offline = true;
      expect(await auth.refreshSession(), isFalse);
      expect(auth.ready, isTrue);
    });
  });
}
