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

  /// Entities rejected with INVALID_FIELD.
  final rejectEntity = <String>{};

  ApiClient client() => ApiClient(baseUrl: 'http://test', client: MockClient(_handle));

  Future<http.Response> _handle(http.Request req) async {
    if (req.url.path != '/api/sync/push') return _json({'code': 'NOT_FOUND'}, 404);
    pushCalls++;
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    final changes = (body['changes'] as List).cast<Map<String, dynamic>>();

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

    final results = [for (final c in changes) _apply(c)];

    if (dropAfterSaving > 0) {
      dropAfterSaving--;
      throw http.ClientException('Connection closed before full answer'); // saved, answer lost
    }
    return _json({'results': results, 'serverTime': '2026-11-26T10:00:00Z', 'cursor': records.length}, 200);
  }

  Map<String, dynamic> _apply(Map<String, dynamic> c) {
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
    if (serverEdit != null) {
      record.addAll(serverEdit);
      result = {'operationId': op, 'status': 'conflictFlagged', 'recordId': id,
        'newVersion': version, 'conflictId': 'conflict-$id', 'record': record};
    } else {
      result = {'operationId': op, 'status': 'applied', 'recordId': id, 'newVersion': version};
    }
    records[key] = record;
    processed[op] = result;
    return result;
  }

  static http.Response _json(Object body, int status) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
}
