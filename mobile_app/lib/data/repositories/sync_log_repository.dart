import '../../core/storage/app_database.dart';
import '../../core/storage/schema.dart';
import '../models/sync_log.dart';

/// The `sync_log` table: one row per sync run (the experiment data).
class SyncLogRepository {
  SyncLogRepository(this._store);

  final AppDatabase _store;

  /// Saves [log] and returns it with its id.
  Future<SyncLog> add(SyncLog log) async {
    final id = await _store.db.insert(Tables.syncLog, log.toMap());
    return SyncLog.fromMap({...log.toMap(), 'id': id});
  }

  /// Newest first.
  Future<List<SyncLog>> recent({int? limit}) async {
    final rows = await _store.db.query(Tables.syncLog, orderBy: 'id DESC', limit: limit);
    return rows.map(SyncLog.fromMap).toList();
  }

  /// All runs, oldest first, as CSV for the pandas scripts
  /// (experiments/scripts). Columns: [SyncLog.csvHeader].
  Future<String> toCsv() async {
    final rows = await _store.db.query(Tables.syncLog, orderBy: 'id');
    final lines = [
      SyncLog.csvHeader.join(','),
      for (final r in rows) SyncLog.fromMap(r).toCsvRow().map(_cell).join(','),
    ];
    return '${lines.join('\n')}\n';
  }

  /// Quotes a cell only when needed (comma, quote or newline inside).
  static String _cell(Object? v) {
    final s = '${v ?? ''}';
    return s.contains(RegExp('[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }
}
