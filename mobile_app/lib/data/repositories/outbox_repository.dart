import 'package:sqflite/sqflite.dart';

import '../../core/storage/app_database.dart';
import '../../core/storage/schema.dart';
import '../models/outbox_entry.dart';

/// Reads and updates the outbox. Rows are only ADDED by the record
/// repositories, inside the same transaction as the record change.
class OutboxRepository {
  OutboxRepository(this._store);

  final AppDatabase _store;
  Database get _db => _store.db;

  /// Pending rows, oldest first (the order they must be sent in).
  Future<List<OutboxEntry>> pending({int? limit}) async {
    final rows = await _db.query(
      Tables.outbox,
      where: 'status = ?',
      whereArgs: [OutboxStatus.pending.name],
      orderBy: 'id',
      limit: limit,
    );
    return rows.map(OutboxEntry.fromMap).toList();
  }

  /// Number of changes waiting to be sent (shown on the sync screen).
  Future<int> pendingCount() async => Sqflite.firstIntValue(await _db.rawQuery(
        'SELECT COUNT(*) FROM ${Tables.outbox} WHERE status = ?',
        [OutboxStatus.pending.name],
      )) ??
      0;

  /// Rows the server rejected; shown to the user, not retried automatically.
  Future<List<OutboxEntry>> failed() async {
    final rows = await _db.query(Tables.outbox,
        where: 'status = ?', whereArgs: [OutboxStatus.failed.name], orderBy: 'id');
    return rows.map(OutboxEntry.fromMap).toList();
  }

  /// +1 attempt for every row in a batch that is about to be sent (E4 counts
  /// retries from this).
  Future<void> recordAttempt(List<String> operationIds) async {
    if (operationIds.isEmpty) return;
    await _db.rawUpdate(
      'UPDATE ${Tables.outbox} SET attempts = attempts + 1 '
      'WHERE operation_id IN (${List.filled(operationIds.length, '?').join(', ')})',
      operationIds,
    );
  }

  /// Removes rows the server confirmed (`applied`, `duplicate`, `conflict…`).
  /// Unconfirmed rows stay and are sent again.
  Future<int> remove(List<String> operationIds) async {
    if (operationIds.isEmpty) return 0;
    return _db.delete(
      Tables.outbox,
      where: 'operation_id IN (${List.filled(operationIds.length, '?').join(', ')})',
      whereArgs: operationIds,
    );
  }

  /// The server rejected this change (api.md section 10).
  Future<void> markFailed(String operationId, String errorCode) => _db.update(
        Tables.outbox,
        {'status': OutboxStatus.failed.name, 'last_error': errorCode},
        where: 'operation_id = ?',
        whereArgs: [operationId],
      );
}
