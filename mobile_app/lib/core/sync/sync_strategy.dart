import '../network/api_client.dart';
import '../storage/app_database.dart';
import 'backoff.dart';
import 'outbox_pusher.dart';
import 'puller.dart';

/// One of the three sync strategies the project compares (api.md §4).
///
/// They all use the same push / pull code; a strategy only decides
///   * what is SENT: every record (S1) or only the outbox (S2, S3),
///   * what is DOWNLOADED: everything (S1) or only changes since the cursor,
///   * which rule the SERVER applies: the `strategy` field in the push
///     request. S1 and S2 overwrite (last upload wins), S3 checks versions
///     and merges fields.
/// So a measured difference between them comes from these choices only.
sealed class SyncStrategy {
  const SyncStrategy(
    this.name, {
    required this.sendsAllRecords,
    required this.pullsEverything,
    required this.detectsConflicts,
  });

  /// `S1`, `S2` or `S3`: sent to the server and written to `sync_log`.
  final String name;
  final bool sendsAllRecords;
  final bool pullsEverything;
  final bool detectsConflicts;

  static const all = <SyncStrategy>[FullSync(), DeltaSync(), VersionedDeltaSync()];

  /// The default: the strategy the project proposes.
  static const fallback = VersionedDeltaSync();

  /// The strategy saved on the phone; unknown or missing → [fallback].
  static SyncStrategy byName(String? name) =>
      all.firstWhere((s) => s.name == name, orElse: () => fallback);

  OutboxPusher pusher(AppDatabase store, ApiClient api,
          {int batchSize = 200, Backoff backoff = const Backoff(), Future<void> Function(Duration)? sleep}) =>
      OutboxPusher(
        store: store,
        api: api,
        strategy: name,
        full: sendsAllRecords,
        batchSize: batchSize,
        backoff: backoff,
        sleep: sleep,
      );

  Future<PullReport> pull(Puller puller) => puller.pullAll(full: pullsEverything);
}

/// S1, the baseline: upload every record, download every record, last
/// upload wins. Simple, but its cost grows with the total number of records.
final class FullSync extends SyncStrategy {
  const FullSync() : super('S1', sendsAllRecords: true, pullsEverything: true, detectsConflicts: false);
}

/// S2: only changes (outbox up, cursor down), last upload wins. Cheap, but
/// when two devices edit the same record one edit is silently lost.
final class DeltaSync extends SyncStrategy {
  const DeltaSync() : super('S2', sendsAllRecords: false, pullsEverything: false, detectsConflicts: false);
}

/// S3, proposed: only changes, plus versions. The server sees when a record
/// changed since the phone last saw it and merges field by field; the same
/// field on both sides keeps the newest and saves the older in history.
final class VersionedDeltaSync extends SyncStrategy {
  const VersionedDeltaSync() : super('S3', sendsAllRecords: false, pullsEverything: false, detectsConflicts: true);
}
