import 'package:sqflite/sqflite.dart';

import '../../core/storage/app_database.dart';
import '../../core/storage/schema.dart';
import '../models/conflict.dart';

/// The phone's copy of the server's open conflicts, so "Check a record"
/// still shows the list with no signal (deciding needs signal).
class ConflictRepository {
  ConflictRepository(this.store);

  final AppDatabase store;

  Future<List<Conflict>> open() async {
    final rows = await store.db.query(Tables.conflicts,
        where: 'status = ?', whereArgs: [Conflict.open], orderBy: 'created_at DESC');
    return rows.map(Conflict.fromMap).toList();
  }

  Future<int> openCount() async =>
      Sqflite.firstIntValue(await store.db.rawQuery(
          'SELECT COUNT(*) FROM ${Tables.conflicts} WHERE status = ?', [Conflict.open])) ??
      0;

  /// Replaces the open list with what the server just sent. Conflicts no
  /// longer open on the server (decided on another phone) disappear.
  Future<void> replaceOpen(List<Conflict> fromServer) => store.db.transaction((txn) async {
        await txn.delete(Tables.conflicts, where: 'status = ?', whereArgs: [Conflict.open]);
        for (final c in fromServer.where((c) => c.isOpen)) {
          await txn.insert(Tables.conflicts, c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

  Future<void> markResolved(String id, String resolution, DateTime at) => store.db.update(
        Tables.conflicts,
        {'status': 'resolved', 'resolution': resolution, 'resolved_at': at.toUtc().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
}
