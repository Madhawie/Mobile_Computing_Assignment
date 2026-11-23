import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:little_bloom/core/auth/auth_controller.dart';
import 'package:little_bloom/core/auth/pin_hasher.dart';
import 'package:little_bloom/core/auth/secure_store.dart';
import 'package:little_bloom/core/network/api_client.dart';
import 'package:little_bloom/core/storage/meta_store.dart';

/// Synthetic accounts known to the fake server (same idea as the dev seed).
const fakeUsers = {
  '+94700000002': ('phm', 'Test PHM', 'glg-east'),
  '+94700000001': ('admin', 'Test Admin', null),
  '+94771234567': ('mother', 'Test Mother', 'glg-east'),
};
const fakeCode = '000000';

/// Fake sign-in server: answers /api/auth/* like api.md section 9.
/// [offline] makes every call fail like a phone with no signal.
class FakeAuthServer {
  bool offline = false;
  final _otps = <String, String>{};

  http.Client get client => MockClient((req) async {
        if (offline) throw http.ClientException('Network is unreachable');
        final body = req.body.isEmpty ? <String, dynamic>{} : jsonDecode(req.body) as Map<String, dynamic>;
        http.Response json(Object b, [int status = 200]) =>
            http.Response(jsonEncode(b), status, headers: {'content-type': 'application/json'});

        switch (req.url.path) {
          case '/api/auth/otp/request':
            final phone = body['phone'] as String;
            if (!fakeUsers.containsKey(phone)) {
              return json({'title': 'Not registered', 'status': 404, 'code': 'PHONE_NOT_REGISTERED'}, 404);
            }
            final id = 'otp-${_otps.length + 1}';
            _otps[id] = phone;
            return json({'otpRequestId': id, 'expiresInSeconds': 300}, 202);
          case '/api/auth/otp/verify':
            final phone = _otps[body['otpRequestId']];
            if (phone == null || body['code'] != fakeCode) {
              return json({'title': 'Wrong code', 'status': 401, 'code': 'INVALID_CODE'}, 401);
            }
            final (role, name, area) = fakeUsers[phone]!;
            return json({
              'accessToken': 'access-$role',
              'expiresIn': 43200,
              'refreshToken': 'refresh-$role',
              'user': {'id': 'u-$role', 'role': role, 'name': name, 'areaId': area, 'mohId': 'glg',
                'motherId': role == 'mother' ? 'm-1' : null},
            });
        }
        return json({'title': 'Not found', 'status': 404, 'code': 'NOT_FOUND'}, 404);
      });
}

/// A controller with in-memory stores. Pass the same stores again to act
/// like the app being closed and opened.
AuthController makeAuth({
  FakeAuthServer? server,
  MemoryMetaStore? meta,
  MemorySecureStore? secure,
}) {
  final s = server ?? FakeAuthServer();
  return AuthController(
    store: meta ?? MemoryMetaStore(),
    secure: secure ?? MemorySecureStore(),
    api: ApiClient(baseUrl: 'http://test', client: s.client),
    pinHasher: const PinHasher(iterations: 500), // fast in tests
  );
}
