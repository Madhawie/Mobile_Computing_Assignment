import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:little_bloom/core/network/api_client.dart';
import 'package:little_bloom/core/network/api_exception.dart';
import 'package:little_bloom/core/network/api_models.dart';
import 'package:little_bloom/core/network/server_settings.dart';

http.Response _json(Object body, {int status = 200, Map<String, String> headers = const {}}) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json', ...headers});

ApiClient _client(MockClientHandler handler, {String? token = 'tok'}) => ApiClient(
      baseUrl: 'http://10.0.2.2:5000/',
      client: MockClient(handler),
      tokenProvider: () => token,
      timeout: const Duration(milliseconds: 200),
    );

void main() {
  group('push', () {
    test('sends the api.md body with token and network profile', () async {
      late http.Request seen;
      final api = _client((req) async {
        seen = req;
        return _json({'results': [], 'serverTime': '2026-11-23T10:00:00Z', 'cursor': 7});
      })
        ..networkProfile = '3G';

      await api.push(deviceId: 'd1', strategy: 'S3', batchId: 'b1', changes: [
        {'operationId': 'op1', 'entity': 'mother'}
      ]);

      expect(seen.method, 'POST');
      expect(seen.url.toString(), 'http://10.0.2.2:5000/api/sync/push');
      expect(seen.headers['Authorization'], 'Bearer tok');
      expect(seen.headers['X-Network-Profile'], '3G');
      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(body['strategy'], 'S3');
      expect((body['changes'] as List).single['operationId'], 'op1');
    });

    test('reads every result status, merged record and error', () async {
      final api = _client((_) async => _json({
            'results': [
              {'operationId': 'a', 'status': 'applied', 'recordId': 'r1', 'newVersion': 2},
              {'operationId': 'b', 'status': 'conflictFlagged', 'recordId': 'r2', 'newVersion': 5,
                'conflictId': 'c9', 'record': {'id': 'r2', 'version': 5}},
              {'operationId': 'c', 'status': 'rejected', 'recordId': 'r3',
                'error': {'code': 'INVALID_FIELD', 'field': 'weightKg'}},
            ],
            'serverTime': '2026-11-23T10:00:00Z',
            'cursor': 42,
          }));
      final res = (await api.push(deviceId: 'd', strategy: 'S3', batchId: 'b', changes: [])).data;
      expect(res.cursor, 42);
      expect(res.results[0].newVersion, 2);
      expect(res.results[1].conflictId, 'c9');
      expect(res.results[1].record!['version'], 5);
      expect(res.results[2].errorCode, 'INVALID_FIELD');
      expect(res.results[2].errorField, 'weightKg');
      expect(res.results.map((r) => ChangeStatus.isConfirmed(r.status)), [true, true, false]);
    });
  });

  test('pull sends since and limit and reads changes', () async {
    late Uri seen;
    final api = _client((req) async {
      seen = req.url;
      return _json({
        'changes': [
          {'entity': 'child', 'record': {'id': 'c1', 'deleted': true}}
        ],
        'cursor': 99,
        'hasMore': true,
      });
    });
    final res = (await api.pull(since: 12, limit: 100)).data;
    expect(seen.queryParameters, {'since': '12', 'limit': '100'});
    expect(res.changes.single.entity, 'child');
    expect(res.changes.single.record['deleted'], true);
    expect((res.cursor, res.hasMore), (99, true));
  });

  group('traffic', () {
    test('counts body and headers both ways and reads server time', () async {
      final api = _client((_) async => _json({'status': 'ok'}, headers: {'x-server-time-ms': '12'}));
      final t = (await api.health()).traffic;
      expect(t.bytesSent, greaterThan('GET /api/health HTTP/1.1\r\n'.length));
      expect(t.bytesReceived, greaterThan(jsonEncode({'status': 'ok'}).length));
      expect(t.serverTimeMs, 12);
      expect(t.durationMs, greaterThanOrEqualTo(0));
    });

    test('a bigger push body costs more bytes', () async {
      final api = _client((_) async => _json({'results': [], 'serverTime': '2026-11-23T10:00:00Z', 'cursor': 0}));
      Future<int> sent(int n) async => (await api.push(
            deviceId: 'd', strategy: 'S1', batchId: 'b',
            changes: List.generate(n, (i) => {'operationId': 'op-$i', 'data': {'notes': 'x' * 50}}),
          ))
              .traffic
              .bytesSent;
      expect(await sent(100), greaterThan(await sent(10)));
    });
  });

  group('failures', () {
    test('ProblemDetails becomes HttpFailure with its code; 4xx is not retried', () async {
      final api = _client((_) async =>
          _json({'title': 'Token expired', 'status': 401, 'code': 'TOKEN_EXPIRED'}, status: 401));
      await expectLater(
        api.pull(since: 0),
        throwsA(isA<HttpFailure>()
            .having((f) => f.code, 'code', 'TOKEN_EXPIRED')
            .having((f) => f.tokenExpired, 'tokenExpired', true)
            .having((f) => f.retryable, 'retryable', false)),
      );
    });

    test('5xx without a body is retryable', () async {
      final api = _client((_) async => http.Response('', 503));
      await expectLater(api.health(),
          throwsA(isA<HttpFailure>().having((f) => f.code, 'code', 'HTTP_503').having((f) => f.retryable, 'r', true)));
    });

    test('no answer in time is a retryable timeout', () async {
      final api = _client((_) => Completer<http.Response>().future); // never answers
      await expectLater(api.health(),
          throwsA(isA<NetworkFailure>().having((f) => f.code, 'code', 'TIMEOUT').having((f) => f.retryable, 'r', true)));
    });

    test('no connection is a retryable network failure', () async {
      final api = _client((_) => throw const SocketException('Network is unreachable'));
      await expectLater(api.health(), throwsA(isA<NetworkFailure>().having((f) => f.code, 'code', 'NETWORK')));
    });
  });

  test('sign-in calls send no token and read the session', () async {
    final seen = <http.Request>[];
    final api = _client((req) async {
      seen.add(req);
      return req.url.path.endsWith('request')
          ? _json({'otpRequestId': 'o1', 'expiresInSeconds': 300}, status: 202)
          : _json({
              'accessToken': 'a', 'expiresIn': 43200, 'refreshToken': 'r',
              'user': {'id': 'u', 'role': 'phm', 'name': 'Test', 'areaId': 'glg-east', 'mohId': 'glg', 'motherId': null},
            });
    });
    final otp = (await api.requestOtp('+94700000002')).data;
    final session = (await api.verifyOtp(otpRequestId: otp.otpRequestId, code: '000000', deviceId: 'd')).data;
    expect(seen.every((r) => !r.headers.containsKey('Authorization')), isTrue);
    expect(session.user.role, 'phm');
    expect(session.user.areaId, 'glg-east');
  });

  group('ServerSettings.normalise', () {
    test('adds http:// and drops paths and slashes', () {
      expect(ServerSettings.normalise(' 192.168.1.20:5000/ '), 'http://192.168.1.20:5000');
      expect(ServerSettings.normalise('https://10.0.2.2:5001/api'), 'https://10.0.2.2:5001');
    });

    test('rejects things that are not a server address', () {
      expect(() => ServerSettings.normalise('ftp://x'), throwsFormatException);
      expect(() => ServerSettings.normalise('http://'), throwsFormatException);
    });
  });
}
