import 'package:sqflite/sqflite.dart';

import '../../data/models/sync_log.dart';
import '../../data/repositories/sync_log_repository.dart';
import '../network/api_client.dart';
import '../storage/app_database.dart';
import '../storage/schema.dart';
import 'backoff.dart';
import 'outbox_pusher.dart';
import 'puller.dart';
import 'sync_strategy.dart';

/// What one sync did; [log] is the row written to `sync_log`.
class SyncResult {
  const SyncResult(this.log, this.push, this.pull);

  final SyncLog log;
  final PushReport push;

  /// Null when the push failed, so no pull was tried.
  final PullReport? pull;

  bool get success => log.success;
}

/// Runs one sync with the chosen strategy and logs it.
///
/// Order: push first, then pull. Pushing first means the pull already
/// contains the server's answer to our own edits (merged records, new
/// versions). If the push fails (no signal), the pull is skipped: it would
/// fail the same way, and the outbox keeps everything for next time.
///
/// EVERY run, successful or not, writes one `sync_log` row: the raw data of
/// the experiments (E1–E6), exported as CSV.
class SyncEngine {
  SyncEngine({
    required this.store,
    required this.api,
    this.batchSize = 200,
    this.pageSize = 500,
    this.overlap = 50,
    this.backoff = const Backoff(),
    this.sleep,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        logs = SyncLogRepository(store);

  final AppDatabase store;
  final ApiClient api;
  final int batchSize;
  final int pageSize;

  /// Pull starts this many change numbers before the cursor (see [Puller]).
  final int overlap;
  final Backoff backoff;

  /// Waits between retries (replaced in tests so they do not really wait).
  final Future<void> Function(Duration)? sleep;
  final DateTime Function() _clock;
  final SyncLogRepository logs;

  bool _running = false;
  bool get running => _running;

  /// The strategy saved on the phone (S3 if none was chosen).
  Future<SyncStrategy> strategy() async => SyncStrategy.byName(await store.getMeta(MetaKeys.syncStrategy));

  /// Chosen on the sync / tester screen; kept across restarts.
  Future<void> setStrategy(SyncStrategy s) => store.setMeta(MetaKeys.syncStrategy, s.name);

  /// One sync. Returns null if a sync is already running (auto-sync and
  /// the "Send now" button can overlap); nothing is logged then.
  ///
  /// [strategy] overrides the saved one for this run (experiments).
  /// [runLabel] names an experiment run, e.g. `E1-500-run3`.
  Future<SyncResult?> syncNow({SyncStrategy? strategy, String? runLabel}) async {
    if (_running) return null;
    _running = true;
    try {
      final s = strategy ?? await this.strategy();
      final startedAt = _clock();
      final watch = Stopwatch()..start();

      final push = await s
          .pusher(store, api, batchSize: batchSize, backoff: backoff, sleep: sleep)
          .pushAll();
      final pull = push.success ? await s.pull(Puller(store: store, api: api, pageSize: pageSize, overlap: overlap)) : null;
      watch.stop();

      final errorCode = push.errorCode ?? pull?.errorCode;
      final log = SyncLog(
        strategy: s.name,
        startedAt: startedAt,
        durationMs: watch.elapsedMilliseconds,
        recordCount: await _recordCount(),
        changedCount: push.sent,
        bytesSent: push.bytesSent + (pull?.bytesSent ?? 0),
        bytesReceived: push.bytesReceived + (pull?.bytesReceived ?? 0),
        networkProfile: api.networkProfile ?? 'direct',
        success: errorCode == null,
        conflicts: push.conflicts,
        duplicates: push.duplicates,
        retries: push.retries,
        errorCode: errorCode,
        runLabel: runLabel,
      );
      final saved = await logs.add(log);
      if (log.success) await store.setMeta(MetaKeys.lastSyncAt, startedAt.toUtc().toIso8601String());
      return SyncResult(saved, push, pull);
    } finally {
      _running = false;
    }
  }

  /// All records on the phone, tombstones included (what S1 uploads).
  Future<int> _recordCount() async {
    var n = 0;
    for (final t in Tables.byEntity.values) {
      n += Sqflite.firstIntValue(await store.db.rawQuery('SELECT COUNT(*) FROM $t')) ?? 0;
    }
    return n;
  }
}
