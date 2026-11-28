import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:little_bloom/core/network/api_client.dart';

/// A tiny in-test sync server for `POST /api/sync/push` (api.md §4).
///
/// Keeps records and processed operationIds like the real server, and can
/// be told to misbehave the way a weak mobile network does.
class FakeSyncServer {
  /// (entity, id) → stored record (with its server `version`).
  final records = <(String, String), Map<String, dynamic>>{};

  /// operationId → the first answer (idempotency).
  final processed = <String, Map<String, dynamic>>{};

  int pushCalls = 0;
  int pullCalls = 0;

  /// Server change number of each record's last write (the pull cursor).
  final seqOf = <(String, String), int>{};
  int changeSeq = 0;

  /// Next N pulls fail with no connection (after [pullFailAfterPages] pages).
  int pullDrops = 0;
  int pullFailAfterPages = 0;

  /// Open conflicts for GET /api/conflicts, and what resolve returns.
  final conflicts = <Map<String, dynamic>>[];
  bool conflictsOffline = false;

  /// Next N pushes: save everything, then lose the answer (connection drops
  /// on the way back). The worst case for duplicates.
  int dropAfterSaving = 0;

  /// Next N pushes: fail before saving anything (no signal).
  int dropBeforeSaving = 0;

  /// Next N pushes: 503 server busy.
  int busy = 0;

  /// Bigger batches get 413 BATCH_TOO_LARGE.
  int maxBatch = 1000;

  /// Next push answers 400 for the whole request.
  bool badRequest = false;

  /// Records whose next change is answered as an S3 conflict, with these
  /// fields changed on the "server side" first.
  final conflictOn = <String, Map<String, dynamic>>{};

  /// `strategy` of the last push, and changes received over all pushes.
  String? lastStrategy;
  int changesReceived = 0;

  /// S1/S2 overwrote an edit made on the server (a lost update, E5).
  int lostUpdates = 0;

  /// Runs inside the next push, before the server answers (e.g. the PHM
  /// edits a record while a sync is on the way).
  Future<void> Function()? duringPush;

  /// Entities rejected with INVALID_FIELD.
  final rejectEntity = <String>{};

  ApiClient client() => ApiClient(baseUrl: 'http://test', client: MockClient(_handle));

  /// Another device (e.g. the clinic) writes a record directly on the server.
  void serverWrite(String entity, Map<String, dynamic> record) {
    final key = (entity, record['id'] as String);
    final version = ((records[key]?['version'] as int?) ?? 0) + 1;
    records[key] = {...?records[key], ...record, 'version': version};
    seqOf[key] = ++changeSeq;
  }

  Future<http.Response> _handle(http.Request req) async {
    if (req.url.path == '/api/sync/pull') return _pull(req);
    if (req.url.path == '/api/conflicts') {
      if (conflictsOffline) throw http.ClientException('Network is unreachable');
      return _json(conflicts.where((c) => c['status'] == 'open').toList(), 200);
    }
    if (req.url.path.startsWith('/api/conflicts/')) return _resolve(req);
    if (req.url.path != '/api/sync/push') return _json({'code': 'NOT_FOUND'}, 404);
    pushCalls++;
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    final changes = (body['changes'] as List).cast<Map<String, dynamic>>();
    lastStrategy = body['strategy'] as String?;

    if (dropBeforeSaving > 0) {
      dropBeforeSaving--;
      throw http.ClientException('Connection reset by peer');
    }
    if (busy > 0) {
      busy--;
      return _json({'title': 'Busy', 'status': 503, 'code': 'SERVER_BUSY'}, 503);
    }
    if (badRequest) {
      badRequest = false;
      return _json({'title': 'Bad', 'status': 400, 'code': 'VALIDATION_FAILED'}, 400);
    }
    if (changes.length > maxBatch) {
      return _json({'title': 'Too large', 'status': 413, 'code': 'BATCH_TOO_LARGE'}, 413);
    }

    final hook = duringPush;
    duringPush = null;
    if (hook != null) await hook();
    changesReceived += changes.length;
    final results = [for (final c in changes) _apply(c, lastStrategy ?? 'S3')];

    if (dropAfterSaving > 0) {
      dropAfterSaving--;
      throw http.ClientException('Connection closed before full answer'); // saved, answer lost
    }
    return _json({'results': results, 'serverTime': '2026-11-26T10:00:00Z', 'cursor': records.length}, 200);
  }

  Map<String, dynamic> _apply(Map<String, dynamic> c, String strategy) {
    final op = c['operationId'] as String;
    final seen = processed[op];
    if (seen != null) return {...seen, 'status': 'duplicate'};

    final entity = c['entity'] as String;
    final id = c['recordId'] as String;
    if (rejectEntity.contains(entity)) {
      return {'operationId': op, 'status': 'rejected', 'recordId': id,
        'error': {'code': 'INVALID_FIELD', 'field': 'x'}};
    }
    final key = (entity, id);
    final version = ((records[key]?['version'] as int?) ?? 0) + 1;
    final record = {...(c['data'] as Map<String, dynamic>), 'version': version};

    final serverEdit = conflictOn.remove(id);
    final Map<String, dynamic> result;
    if (serverEdit != null && strategy != 'S3') {
      // S1 / S2: last upload wins; the other device's edit is silently gone.
      lostUpdates++;
      result = {'operationId': op, 'status': 'applied', 'recordId': id, 'newVersion': version};
    } else if (serverEdit != null) {
      record.addAll(serverEdit);
      result = {'operationId': op, 'status': 'conflictFlagged', 'recordId': id,
        'newVersion': version, 'conflictId': 'conflict-$id', 'record': record};
    } else {
      result = {'operationId': op, 'status': 'applied', 'recordId': id, 'newVersion': version};
    }
    records[key] = record;
    seqOf[key] = ++changeSeq;
    processed[op] = result;
    return result;
  }

  Future<http.Response> _pull(http.Request req) async {
    pullCalls++;
    if (pullDrops > 0 && pullCalls > pullFailAfterPages) {
      pullDrops--;
      throw http.ClientException('Connection reset during pull');
    }
    final since = int.parse(req.url.queryParameters['since'] ?? '0');
    final limit = int.parse(req.url.queryParameters['limit'] ?? '500');
    final newer = seqOf.entries.where((e) => e.value > since).toList()..sort((a, b) => a.value.compareTo(b.value));
    final page = newer.take(limit).toList();
    return _json({
      'changes': [for (final e in page) {'entity': e.key.$1, 'record': records[e.key]}],
      'cursor': page.isEmpty ? since : page.last.value,
      'hasMore': newer.length > limit,
    }, 200);
  }

  Future<http.Response> _resolve(http.Request req) async {
    if (conflictsOffline) throw http.ClientException('Network is unreachable');
    final id = req.url.pathSegments[2];
    final keep = (jsonDecode(req.body) as Map<String, dynamic>)['keep'] as String;
    final c = conflicts.firstWhere((c) => c['id'] == id);
    c['status'] = 'resolved';
    final key = (c['entity'] as String, c['recordId'] as String);
    if (keep == 'previous') {
      final f = (c['fields'] as List).first as Map<String, dynamic>;
      serverWrite(key.$1, {'id': key.$2, f['field'] as String: f['lost']});
    }
    return _json({'conflictId': id, 'resolution': keep, 'version': records[key]!['version'], 'record': records[key]}, 200);
  }

  static http.Response _json(Object body, int status) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
}
