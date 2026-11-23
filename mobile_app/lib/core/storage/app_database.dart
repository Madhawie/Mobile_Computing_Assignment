import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'meta_store.dart';
import 'schema.dart';

/// Opens the phone's SQLite database and keeps small settings in `meta`.
///
/// All reads in the app are local (offline-first); repositories (Day 6)
/// use [db] to read and write records and the outbox.
class AppDatabase implements MetaStore {
  AppDatabase._(this.db);

  /// File name inside the app's private database folder. Never committed.
  static const fileName = 'little_bloom.db';

  final Database db;

  /// Opens (and creates or upgrades) the database.
  ///
  /// Tests pass `databaseFactoryFfi` and `inMemoryDatabasePath` so they run
  /// on the Mac without an emulator.
  static Future<AppDatabase> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), fileName);
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, version) async {
          await _runAll(db, schemaV1);
          await runMigrations(db, from: 1, to: version);
        },
        onUpgrade: (db, oldVersion, newVersion) =>
            runMigrations(db, from: oldVersion, to: newVersion),
      ),
    );
    return AppDatabase._(db);
  }

  /// Applies migration steps to go from version [from] to [to].
  /// Step `i` in [steps] upgrades version `i + 1` to `i + 2`.
  /// sqflite runs onCreate / onUpgrade in a transaction, so a failed step
  /// leaves the old database unchanged.
  static Future<void> runMigrations(
    DatabaseExecutor db, {
    required int from,
    required int to,
    List<List<String>> steps = migrations,
  }) async {
    for (var v = from; v < to; v++) {
      await _runAll(db, steps[v - 1]);
    }
  }

  static Future<void> _runAll(DatabaseExecutor db, List<String> statements) async {
    for (final sql in statements) {
      await db.execute(sql);
    }
  }

  // ---- meta (key / value settings) ----

  @override
  Future<String?> getMeta(String key) async {
    final rows = await db.query(Tables.meta, where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  @override
  Future<void> setMeta(String key, String? value) => db.insert(
        Tables.meta,
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// This phone's id, made once and then kept. Sent as `deviceId` with every
  /// change so the server knows which phone edited a record.
  @override
  Future<String> deviceId() async {
    final existing = await getMeta(MetaKeys.deviceId);
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await setMeta(MetaKeys.deviceId, id);
    return id;
  }

  // ---- helpers for the sync screen and experiments ----

  /// Number of rows in each table (sync screen, experiment checks).
  Future<Map<String, int>> tableCounts() async {
    final counts = <String, int>{};
    for (final t in [...Tables.byEntity.values, Tables.outbox, Tables.syncLog]) {
      counts[t] = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $t')) ?? 0;
    }
    return counts;
  }

  /// Empties records, outbox and pull cursor before an experiment run.
  /// Keeps the device id and the sync log (the results).
  Future<void> resetForExperiment() => db.transaction((txn) async {
        for (final t in [...Tables.byEntity.values, Tables.outbox]) {
          await txn.delete(t);
        }
        await txn.delete(Tables.meta, where: 'key IN (?, ?)',
            whereArgs: [MetaKeys.pullCursor, MetaKeys.lastSyncAt]);
      });

  Future<void> close() => db.close();
}
