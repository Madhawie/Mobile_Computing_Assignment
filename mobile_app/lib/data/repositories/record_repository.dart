import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/app_database.dart';
import '../../core/storage/schema.dart';
import '../models/outbox_entry.dart';
import '../models/sync_record.dart';

/// Turns a SQLite row into a model.
typedef FromMap<T> = T Function(Map<String, dynamic> row);

/// Read and write one kind of record, offline.
///
/// The offline-first rule: every change runs in ONE transaction that
/// 1. writes the record with `version + 1` and `is_dirty = 1`, and
/// 2. adds an outbox row with a new UUID `operation_id`.
/// So a change is either saved and queued, or not saved at all.
///
/// Reads are always local; the sync engine (Days 11–13) sends the outbox.
class RecordRepository<T extends SyncRecord> {
  RecordRepository(
    this.store, {
    required this.table,
    required this.entity,
    required this.fromMap,
    DateTime Function()? clock,
    Uuid? uuid,
  })  : _clock = clock ?? DateTime.now,
        _uuid = uuid ?? const Uuid();

  final AppDatabase store;
  final String table;

  /// `entity` value in the API, e.g. `growthMeasurement`.
  final String entity;
  final FromMap<T> fromMap;
  final DateTime Function() _clock;
  final Uuid _uuid;

  Database get db => store.db;

  // ---------------------------------------------------------------- reads

  /// One record, or null. Deleted records are hidden unless asked for.
  Future<T?> getById(String id, {bool includeDeleted = false}) async {
    final row = await _row(db, id);
    if (row == null || (!includeDeleted && row['deleted'] == 1)) return null;
    return fromMap(row);
  }

  /// Records that are not deleted, filtered by an optional SQL [where].
  Future<List<T>> list({String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final rows = await db.query(
      table,
      where: where == null ? 'deleted = 0' : 'deleted = 0 AND ($where)',
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
    return rows.map(fromMap).toList();
  }

  // --------------------------------------------------------------- writes

  /// Saves a new record and queues it.
  ///
  /// The caller fills the record's own fields; the repository sets the sync
  /// fields: a new UUID if [draft] has an empty id, `version = 1`,
  /// `updatedAt = now`, this phone's `deviceId`, `isDirty = true`.
  Future<T> create(T draft) async {
    final deviceId = await store.deviceId();
    return db.transaction((txn) async {
      final map = draft.toMap()
        ..['id'] = draft.id.isEmpty ? _uuid.v4() : draft.id
        ..['version'] = 1
        ..['server_version'] = 0
        ..['updated_at'] = _now()
        ..['device_id'] = deviceId
        ..['deleted'] = 0
        ..['is_dirty'] = 1;
      await txn.insert(table, map, conflictAlgorithm: ConflictAlgorithm.abort);
      final saved = fromMap(map);
      await _queue(
        txn,
        saved,
        op: OutboxOp.upsert,
        baseVersion: 0,
        changedFields: saved.dataToJson().keys.toList(),
      );
      return saved;
    });
  }

  /// Saves an edit and queues it. Only fields that really changed are listed
  /// in `changedFields` (used by S3 for field-level merge). If nothing
  /// changed, nothing is written or queued.
  Future<T> update(T edited) async {
    final deviceId = await store.deviceId();
    return db.transaction((txn) async {
      final currentRow = await _row(txn, edited.id);
      if (currentRow == null || currentRow['deleted'] == 1) {
        throw StateError('$entity ${edited.id} not found');
      }
      final current = fromMap(currentRow);
      final changed = _changedFields(current, edited);
      if (changed.isEmpty) return current;

      final map = edited.toMap()
        ..['version'] = current.version + 1
        ..['server_version'] = currentRow['server_version']
        ..['updated_at'] = _now()
        ..['device_id'] = deviceId
        ..['deleted'] = 0
        ..['is_dirty'] = 1;
      await txn.update(table, map, where: 'id = ?', whereArgs: [edited.id]);
      final saved = fromMap(map);
      await _queue(
        txn,
        saved,
        op: OutboxOp.upsert,
        baseVersion: await _baseVersion(txn, currentRow),
        changedFields: changed,
      );
      return saved;
    });
  }

  /// Soft delete: the row stays with `deleted = 1` (a tombstone) and a
  /// `delete` change is queued.
  ///
  /// Why not a real DELETE? The other phones and the server must learn about
  /// the delete. If the row simply vanished, nothing would be sent, and the
  /// next pull would bring the record back ("resurrection").
  ///
  /// Deleting a record that is already deleted does nothing.
  Future<void> softDelete(String id) async {
    final deviceId = await store.deviceId();
    await db.transaction((txn) async {
      final currentRow = await _row(txn, id);
      if (currentRow == null) throw StateError('$entity $id not found');
      if (currentRow['deleted'] == 1) return;

      final map = Map<String, dynamic>.of(currentRow)
        ..['version'] = (currentRow['version'] as int) + 1
        ..['updated_at'] = _now()
        ..['device_id'] = deviceId
        ..['deleted'] = 1
        ..['is_dirty'] = 1;
      await txn.update(table, map, where: 'id = ?', whereArgs: [id]);
      await _queue(
        txn,
        fromMap(map),
        op: OutboxOp.delete,
        baseVersion: await _baseVersion(txn, currentRow),
        changedFields: const ['deleted'],
      );
    });
  }

  // -------------------------------------------------------------- helpers

  Future<Map<String, dynamic>?> _row(DatabaseExecutor ex, String id) async {
    final rows = await ex.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  String _now() => _clock().toUtc().toIso8601String();

  /// API names (camelCase) of the record's own fields whose value changed.
  List<String> _changedFields(T before, T after) {
    final a = before.dataToJson(), b = after.dataToJson();
    return [for (final k in b.keys) if (a[k] != b[k]) k];
  }

  /// The server version this edit starts from (`baseVersion`, api.md §4).
  ///
  /// = last confirmed server version + edits still waiting in the outbox for
  /// this record. Each queued edit raises the server version by 1 when it is
  /// applied, so a second offline edit of the same record does not look like
  /// a conflict with the phone's own first edit.
  Future<int> _baseVersion(DatabaseExecutor ex, Map<String, dynamic> currentRow) async {
    final waiting = Sqflite.firstIntValue(await ex.rawQuery(
          'SELECT COUNT(*) FROM ${Tables.outbox} WHERE record_id = ? AND status = ?',
          [currentRow['id'], OutboxStatus.pending.name],
        )) ??
        0;
    return (currentRow['server_version'] as int) + waiting;
  }

  Future<void> _queue(
    DatabaseExecutor ex,
    T saved, {
    required OutboxOp op,
    required int baseVersion,
    required List<String> changedFields,
  }) =>
      ex.insert(
        Tables.outbox,
        OutboxEntry(
          operationId: _uuid.v4(),
          entity: entity,
          op: op,
          recordId: saved.id,
          baseVersion: baseVersion,
          changedFields: changedFields,
          payload: saved.toJson(),
          createdAt: _clock(),
        ).toMap(),
      );
}
