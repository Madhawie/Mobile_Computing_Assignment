import 'package:uuid/uuid.dart';

import '../../data/repositories/outbox_repository.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../network/api_models.dart';
import '../storage/app_database.dart';
import 'sync_store.dart';

/// Totals of one push run. These numbers go into `sync_log` (Day 13).
class PushReport {
  int batches = 0;
  int sent = 0;
  int applied = 0;
  int duplicates = 0;
  int merged = 0;
  int flagged = 0;
  int rejected = 0;
  int retries = 0;
  int bytesSent = 0;
  int bytesReceived = 0;
  int durationMs = 0;
  final conflictIds = <String>[];

  /// Set when the run stopped early (e.g. `NETWORK`, `TIMEOUT`, `HTTP_503`).
  /// Rows not confirmed stay in the outbox.
  String? errorCode;

  bool get success => errorCode == null;
  int get conflicts => merged + flagged;

  void add(BatchOutcome o) {
    applied += o.applied;
    duplicates += o.duplicates;
    merged += o.merged;
    flagged += o.flagged;
    rejected += o.rejected;
    conflictIds.addAll(o.conflictIds);
  }
}

/// Sends the outbox to `POST /api/sync/push` (api.md §4), oldest first, in
/// batches of at most [batchSize].
///
/// Strategy S3 (versioned delta): each change carries `baseVersion` and
/// `changedFields`, so the server can detect and merge conflicts. Confirmed
/// changes leave the outbox; unconfirmed ones stay for the next run. Because
/// every change keeps its `operationId`, sending one twice is harmless: the
/// server answers `duplicate`.
class OutboxPusher {
  OutboxPusher({
    required this.store,
    required this.api,
    this.strategy = 'S3',
    this.batchSize = 200,
    Uuid? uuid,
  })  : _uuid = uuid ?? const Uuid(),
        _outbox = OutboxRepository(store),
        _sync = SyncStore(store);

  final AppDatabase store;
  final ApiClient api;
  final String strategy;
  int batchSize;
  final Uuid _uuid;
  final OutboxRepository _outbox;
  final SyncStore _sync;

  bool _running = false;

  /// True while a push is running; a second call waits for nothing and
  /// returns at once (auto-sync and the "Send now" button may overlap).
  bool get running => _running;

  Future<PushReport> pushAll() async {
    final report = PushReport();
    if (_running) return report..errorCode = 'BUSY';
    _running = true;
    final watch = Stopwatch()..start();
    try {
      final deviceId = await store.deviceId();
      while (true) {
        final batch = await _outbox.pending(limit: batchSize);
        if (batch.isEmpty) break;

        final ids = batch.map((e) => e.operationId).toList();
        await _outbox.recordAttempt(ids);
        final ApiResult<PushResponse> res;
        try {
          res = await api.push(
            deviceId: deviceId,
            strategy: strategy,
            batchId: _uuid.v4(),
            changes: batch.map((e) => e.toChangeJson()).toList(),
          );
        } on ApiFailure catch (f) {
          report.errorCode = f.code;
          break; // rows stay in the outbox
        }

        report.batches++;
        report.sent += batch.length;
        report.bytesSent += res.traffic.bytesSent;
        report.bytesReceived += res.traffic.bytesReceived;
        final outcome = await _sync.applyResults(batch, res.data.results);
        report.add(outcome);
        if (outcome.confirmed + outcome.rejected == 0) {
          report.errorCode = 'NO_PROGRESS'; // server answered but confirmed nothing
          break;
        }
      }
    } finally {
      _running = false;
      report.durationMs = watch.elapsedMilliseconds;
    }
    return report;
  }
}
