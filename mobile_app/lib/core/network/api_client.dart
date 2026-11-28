import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../data/models/conflict.dart';
import 'api_exception.dart';
import 'api_models.dart';

/// Gives the current access token, or null when signed out.
typedef TokenProvider = FutureOr<String?> Function();

/// Gets a new access token after a 401 `TOKEN_EXPIRED`. True = try again.
typedef TokenRefresher = Future<bool> Function();

/// Size and time of one request, for `sync_log` and the experiments.
class Traffic {
  const Traffic({
    required this.bytesSent,
    required this.bytesReceived,
    required this.durationMs,
    this.serverTimeMs,
  });

  /// Request line + headers + body, in bytes (UTF-8).
  final int bytesSent;

  /// Status line + headers + body, in bytes.
  final int bytesReceived;

  /// Time from sending to the full answer, measured on the phone.
  final int durationMs;

  /// `X-Server-Time-Ms`: time spent inside the server. Network time is
  /// roughly [durationMs] minus this.
  final int? serverTimeMs;
}

/// A decoded answer plus its [traffic].
class ApiResult<T> {
  const ApiResult(this.data, this.traffic);

  final T data;
  final Traffic traffic;
}

/// Talks to the Little Bloom API (docs/architecture/api.md).
///
/// * Every call has a timeout, so a weak signal fails fast instead of hanging.
/// * Every call counts the bytes it sent and received, and how long it took.
///   These counts are an application-level estimate (HTTP/1.1 text, no TCP /
///   TLS overhead); Wireshark is used for the exact numbers in the report.
/// * Errors become [ApiFailure]s that say whether a retry makes sense.
class ApiClient {
  ApiClient({
    required String baseUrl,
    this.tokenProvider,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    this.networkProfile,
    this.onTokenExpired,
  })  : baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _http = client ?? http.Client();

  /// e.g. `http://10.0.2.2:5000` (no trailing slash).
  final String baseUrl;
  final Duration timeout;

  /// Sent as `X-Network-Profile` (4G / 3G / 2G) so server logs match the
  /// phone's sync log during experiments.
  String? networkProfile;

  /// Gives the access token for `Authorization: Bearer …`.
  final TokenProvider? tokenProvider;

  /// Set by main.dart to `AuthController.refreshSession`. When a signed-in
  /// call answers 401 `TOKEN_EXPIRED` (the 12 h access token ran out), the
  /// client asks for new tokens once and sends the same request again, so a
  /// sync started the morning after works without signing in again.
  TokenRefresher? onTokenExpired;
  final http.Client _http;

  // ----------------------------------------------------------- endpoints

  Future<ApiResult<bool>> health() =>
      _send('GET', '/api/health', auth: false, decode: (_) => true);

  Future<ApiResult<OtpRequest>> requestOtp(String phone) => _send(
        'POST',
        '/api/auth/otp/request',
        body: {'phone': phone},
        auth: false,
        decode: (j) => OtpRequest.fromJson(j as Map<String, dynamic>),
      );

  Future<ApiResult<AuthSession>> verifyOtp({
    required String otpRequestId,
    required String code,
    required String deviceId,
  }) =>
      _send(
        'POST',
        '/api/auth/otp/verify',
        body: {'otpRequestId': otpRequestId, 'code': code, 'deviceId': deviceId},
        auth: false,
        decode: (j) => AuthSession.fromJson(j as Map<String, dynamic>),
      );

  Future<ApiResult<AuthSession>> refresh({required String refreshToken, required String deviceId}) =>
      _send(
        'POST',
        '/api/auth/refresh',
        body: {'refreshToken': refreshToken, 'deviceId': deviceId},
        auth: false,
        decode: (j) => AuthSession.fromJson(j as Map<String, dynamic>),
      );

  /// `POST /api/sync/push`. [changes] are `OutboxEntry.toChangeJson()` items.
  Future<ApiResult<PushResponse>> push({
    required String deviceId,
    required String strategy,
    required String batchId,
    required List<Map<String, dynamic>> changes,
  }) =>
      _send(
        'POST',
        '/api/sync/push',
        body: {'deviceId': deviceId, 'strategy': strategy, 'batchId': batchId, 'changes': changes},
        decode: (j) => PushResponse.fromJson(j as Map<String, dynamic>),
      );

  /// `GET /api/sync/pull?since=&limit=`. S1 passes `since: 0`.
  Future<ApiResult<PullResponse>> pull({required int since, int limit = 500}) => _send(
        'GET',
        '/api/sync/pull',
        query: {'since': '$since', 'limit': '$limit'},
        decode: (j) => PullResponse.fromJson(j as Map<String, dynamic>),
      );

  /// `GET /api/conflicts?status=open` – S3 conflicts in the user's area.
  Future<ApiResult<List<Conflict>>> conflicts({String status = Conflict.open}) => _send(
        'GET',
        '/api/conflicts',
        query: {'status': status},
        decode: (j) => (j as List).map((c) => Conflict.fromJson(c as Map<String, dynamic>)).toList(),
      );

  /// `POST /api/conflicts/{id}/resolve` with `keep: current | previous`.
  Future<ApiResult<ResolveResult>> resolveConflict(String id, {required String keep}) => _send(
        'POST',
        '/api/conflicts/$id/resolve',
        body: {'keep': keep},
        decode: (j) => ResolveResult.fromJson(j as Map<String, dynamic>),
      );

  void close() => _http.close();

  // ------------------------------------------------------------ plumbing

  Future<ApiResult<T>> _send<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
    required T Function(Object? json) decode,
  }) async {
    try {
      return await _sendOnce(method, path, body: body, query: query, auth: auth, decode: decode);
    } on HttpFailure catch (f) {
      final refresh = onTokenExpired;
      if (!auth || !f.tokenExpired || refresh == null || !await refresh()) rethrow;
      // Same request, new token. The 401 try is small and left out of the
      // traffic counts; a second TOKEN_EXPIRED is not retried again.
      return _sendOnce(method, path, body: body, query: query, auth: auth, decode: decode);
    }
  }

  Future<ApiResult<T>> _sendOnce<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    required bool auth,
    required T Function(Object? json) decode,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.bodyBytes = utf8.encode(jsonEncode(body));
    }
    if (networkProfile != null) request.headers['X-Network-Profile'] = networkProfile!;
    if (auth && tokenProvider != null) {
      final t = await tokenProvider!();
      if (t != null) request.headers['Authorization'] = 'Bearer $t';
    }

    final watch = Stopwatch()..start();
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(timeout))
          .timeout(timeout);
    } on TimeoutException {
      throw NetworkFailure('No answer within ${timeout.inSeconds} s', timedOut: true);
    } on SocketException catch (e) {
      throw NetworkFailure(e.message);
    } on http.ClientException catch (e) {
      throw NetworkFailure(e.message);
    }
    watch.stop();

    final traffic = Traffic(
      bytesSent: _requestSize(request),
      bytesReceived: _responseSize(response),
      durationMs: watch.elapsedMilliseconds,
      serverTimeMs: int.tryParse(response.headers['x-server-time-ms'] ?? ''),
    );

    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (response.statusCode >= 400) throw _failure(response.statusCode, text);
    return ApiResult(decode(text.isEmpty ? null : jsonDecode(text)), traffic);
  }

  /// Reads a ProblemDetails body (`code`, `title`); falls back to the status.
  HttpFailure _failure(int status, String text) {
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      return HttpFailure(status, j['code'] as String? ?? 'HTTP_$status',
          j['title'] as String? ?? j['detail'] as String? ?? 'HTTP $status');
    } catch (_) {
      return HttpFailure(status, 'HTTP_$status', 'HTTP $status');
    }
  }

  static int _headersSize(Map<String, String> headers) =>
      headers.entries.fold(0, (n, h) => n + utf8.encode('${h.key}: ${h.value}\r\n').length);

  /// "METHOD /path?query HTTP/1.1\r\n" + Host + headers + blank line + body.
  static int _requestSize(http.Request r) {
    final target = r.url.hasQuery ? '${r.url.path}?${r.url.query}' : r.url.path;
    final hostLine = 'Host: ${r.url.host}${r.url.hasPort ? ':${r.url.port}' : ''}\r\n';
    return utf8.encode('${r.method} $target HTTP/1.1\r\n').length +
        utf8.encode(hostLine).length +
        _headersSize(r.headers) +
        2 +
        r.bodyBytes.length;
  }

  /// "HTTP/1.1 200 OK\r\n" + headers + blank line + body.
  static int _responseSize(http.Response r) =>
      utf8.encode('HTTP/1.1 ${r.statusCode} ${r.reasonPhrase ?? ''}\r\n').length +
      _headersSize(r.headers) +
      2 +
      r.bodyBytes.length;
}
