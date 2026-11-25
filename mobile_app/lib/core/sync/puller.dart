import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../storage/app_database.dart';
import '../storage/schema.dart';
import 'sync_store.dart';

/// Totals of one pull run, for the sync log.
class PullReport {
  int pages = 0;
  int received = 0;
  int applied = 0;
  int tombstones = 0;
  int keptLocal = 0;
  int stale = 0;
  int invalid = 0;
  int bytesSent = 0;
  int bytesReceived = 0;
  int durationMs = 0;
  int? cursor;
  String? errorCode;

  bool get success => errorCode == null;

  void add(PullOutcome o) {
    received += o.received;
    applied += o.applied;
    tombstones += o.tombstones;
    keptLocal += o.keptLocal;
    stale += o.stale;
    invalid += o.invalid;
  }
}

/// Downloads server changes with `GET /api/sync/pull?since=&limit=` (api.md §5).
///
/// * `since` is the server's change number stored after the last pull (not a
///   time, so wrong phone clocks do not matter).
/// * Starts [overlap] numbers earlier than the stored cursor: the server
///   notes that two pushes committing out of order can make a pull skip a
///   row once. Applying a record twice changes nothing, so the overlap only
///   costs a few repeated rows.
/// * Pages until `hasMore` is false, saving the cursor after every page, so a
///   pull cut off half way continues from the last saved page.
/// * [full] (strategy S1) ignores the cursor and downloads everything.
class Puller {
  Puller({required this.store, required this.api, this.pageSize = 500, this.overlap = 50})
      : _sync = SyncStore(store);

  final AppDatabase store;
  final ApiClient api;
  final int pageSize;
  final int overlap;
  final SyncStore _sync;

  Future<int?> savedCursor() async => int.tryParse(await store.getMeta(MetaKeys.pullCursor) ?? '');

  Future<PullReport> pullAll({bool full = false}) async {
    final report = PullReport();
    final watch = Stopwatch()..start();
    final saved = await savedCursor();
    var since = full || saved == null ? 0 : (saved - overlap).clamp(0, saved);
    try {
      while (true) {
        final res = await api.pull(since: since, limit: pageSize);
        report.pages++;
        report.bytesSent += res.traffic.bytesSent;
        report.bytesReceived += res.traffic.bytesReceived;
        report.add(await _sync.applyPulled(res.data.changes));

        // Never move the stored cursor backwards (the overlap starts lower).
        final next = res.data.cursor;
        final current = await savedCursor();
        if (current == null || next > current) await store.setMeta(MetaKeys.pullCursor, '$next');
        report.cursor = next;

        if (!res.data.hasMore || next <= since) break;
        since = next;
      }
    } on ApiFailure catch (f) {
      report.errorCode = f.code; // pages already applied stay applied
    } finally {
      report.durationMs = watch.elapsedMilliseconds;
    }
    return report;
  }
}
