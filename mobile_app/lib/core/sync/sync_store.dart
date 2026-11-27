import 'package:sqflite/sqflite.dart';

import '../../data/models/models.dart';
import '../network/api_models.dart';
import '../storage/app_database.dart';
import '../storage/schema.dart';

/// What one batch's answers did on the phone.
class BatchOutcome {
  int applied = 0;
  int duplicates = 0;
  int merged = 0;
  int flagged = 0;
  int rejected = 0;

  /// Sent but not in the answer: they stay in the outbox and go again.
  int unconfirmed = 0;
  final conflictIds = <String>[];

  int get confirmed => applied + duplicates + merged + flagged;
}

/// Applies the server's push answers to the phone's database (api.md §4).
///
/// For each change, in ONE transaction for the whole batch:
/// * applied / duplicate → remove the outbox row; remember the server's
///   version; the record is clean again when nothing else is queued for it.
/// * conflictMerged / conflictFlagged → same, and take the server's merged
///   record (unless the phone has newer edits of it still queued).
/// * rejected → keep the row, marked failed, with the error code.
/// * no answer → leave the row as it is; it will be sent again.
class SyncStore {
  SyncStore(this.store);

  final AppDatabase store;

  Future<BatchOutcome> applyResults(List<OutboxEntry> sent, List<ChangeResult> results) {
    final byOp = {for (final e in sent) e.operationId: e};
    final outcome = BatchOutcome()..unconfirmed = sent.length;

    return store.db.transaction((txn) async {
      for (final r in results) {
        final entry = byOp[r.operationId];
        if (entry == null) continue; // not ours (should not happen)
        outcome.unconfirmed--;

        if (r.status == ChangeStatus.rejected) {
          outcome.rejected++;
          await txn.update(
            Tables.outbox,
            {'status': OutboxStatus.failed.name, 'last_error': r.errorCode ?? 'REJECTED'},
            where: 'operation_id = ?',
            whereArgs: [r.operationId],
          );
          continue;
        }

        await txn.delete(Tables.outbox, where: 'operation_id = ?', whereArgs: [r.operationId]);
        await _confirmRecord(txn, entry, r);

        switch (r.status) {
          case ChangeStatus.applied:
            outcome.applied++;
          case ChangeStatus.duplicate:
            outcome.duplicates++;
          case ChangeStatus.conflictMerged:
            outcome.merged++;
          case ChangeStatus.conflictFlagged:
            outcome.flagged++;
            if (r.conflictId != null) outcome.conflictIds.add(r.conflictId!);
        }
      }
      return outcome;
    });
  }

  Future<void> _confirmRecord(Transaction txn, OutboxEntry entry, ChangeResult r) async {
    final table = Tables.byEntity[entry.entity];
    if (table == null) return;
    final stillQueued = Sqflite.firstIntValue(await txn.rawQuery(
          'SELECT COUNT(*) FROM ${Tables.outbox} WHERE record_id = ? AND status = ?',
          [entry.recordId, OutboxStatus.pending.name],
        )) ??
        0;
    final newVersion = r.newVersion;

    // The server merged our edit with someone else's: show the merged record,
    // unless a newer edit of ours is still waiting (it will be merged next).
    if (r.record != null && stillQueued == 0) {
      final merged = recordFromJson(entry.entity, r.record!).toMap()
        ..['server_version'] = r.record!['version']
        ..['is_dirty'] = 0;
      await txn.insert(table, merged, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }
    if (newVersion == null) return;

    // Keep the highest confirmed version (answers can come back out of order
    // after a retry). When nothing else is queued, the record is clean and
    // its version equals the server's.
    await txn.rawUpdate(
      stillQueued == 0
          ? 'UPDATE $table SET server_version = MAX(server_version, ?), version = MAX(version, ?), is_dirty = 0 WHERE id = ?'
          : 'UPDATE $table SET server_version = MAX(server_version, ?) WHERE id = ?',
      stillQueued == 0 ? [newVersion, newVersion, entry.recordId] : [newVersion, entry.recordId],
    );
  }
}
