import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/storage/app_database.dart';
import 'package:little_bloom/core/storage/schema.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Synthetic test data only.
final _t = DateTime.utc(2026, 11, 22, 9);

SyncRecord _sample(String entity) => switch (entity) {
      'mother' => Mother(
          id: 'm-1', version: 1, updatedAt: _t, deviceId: 'd', isDirty: true,
          fullName: 'Test Mother', phone: '+94700000001', age: 25, address: 'Test Road',
          areaId: 'area-1', isPregnant: true, gestationWeeks: 20, dueDate: DateTime(2027, 4, 1)),
      'maternalVisit' => MaternalVisit(
          id: 'v-1', version: 1, updatedAt: _t, deviceId: 'd', motherId: 'm-1',
          visitDate: DateTime(2026, 11, 22), gestationWeeks: 20, weightKg: 60.2,
          bpSystolic: 118, bpDiastolic: 76, notes: 'ok'),
      'child' => Child(
          id: 'c-1', version: 1, updatedAt: _t, deviceId: 'd', motherId: 'm-1', name: 'Test Baby',
          sex: Sex.boy, dateOfBirth: DateTime(2026, 1, 5), birthWeightKg: 3.1),
      'growthMeasurement' => GrowthMeasurement(
          id: 'g-1', version: 2, updatedAt: _t, deviceId: 'd', deleted: true, childId: 'c-1',
          measuredOn: DateTime(2026, 11, 22), weightKg: 8.3, heightCm: 70.5),
      'vaccination' => Vaccination(
          id: 'x-1', version: 1, updatedAt: _t, deviceId: 'd', childId: 'c-1',
          vaccine: 'MMR', dose: 1, givenOn: DateTime(2026, 10, 5)),
      _ => throw ArgumentError(entity),
    };

SyncRecord _fromMap(String entity, Map<String, dynamic> m) => switch (entity) {
      'mother' => Mother.fromMap(m),
      'maternalVisit' => MaternalVisit.fromMap(m),
      'child' => Child.fromMap(m),
      'growthMeasurement' => GrowthMeasurement.fromMap(m),
      'vaccination' => Vaccination.fromMap(m),
      _ => throw ArgumentError(entity),
    };

OutboxEntry _entry(String opId) => OutboxEntry(
      operationId: opId, entity: 'mother', op: OutboxOp.upsert, recordId: 'm-1',
      baseVersion: 0, changedFields: const ['fullName'], payload: const {'id': 'm-1'},
      createdAt: _t,
    );

void main() {
  sqfliteFfiInit();
  late AppDatabase store;

  setUp(() async {
    store = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
  });
  tearDown(() => store.close());

  test('creates every table', () async {
    final rows = await store.db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
    final names = rows.map((r) => r['name']).toSet();
    expect(names, containsAll([...Tables.byEntity.values, Tables.outbox, Tables.syncLog, Tables.meta]));
  });

  test('schemaVersion matches the migration list', () {
    expect(schemaVersion, 1 + migrations.length);
  });

  group('every model fits its table', () {
    for (final entry in Tables.byEntity.entries) {
      test('${entry.key} → ${entry.value}', () async {
        final record = _sample(entry.key);
        await store.db.insert(entry.value, record.toMap());
        final row = (await store.db.query(entry.value)).single;
        expect(_fromMap(entry.key, row).toMap(), record.toMap());
        // phone-only column has its default
        expect(row['server_version'], 0);
      });
    }
  });

  test('sex must be boy or girl', () async {
    final m = _sample('child').toMap()..['sex'] = 'other';
    expect(() => store.db.insert(Tables.children, m), throwsA(isA<DatabaseException>()));
  });

  group('outbox', () {
    test('keeps the order changes were made', () async {
      for (final id in ['op-a', 'op-b', 'op-c']) {
        await store.db.insert(Tables.outbox, _entry(id).toMap());
      }
      final rows = await store.db.query(Tables.outbox, orderBy: 'id');
      expect(rows.map((r) => r['operation_id']), ['op-a', 'op-b', 'op-c']);
      expect(OutboxEntry.fromMap(rows.first).changedFields, ['fullName']);
    });

    test('the same operation_id cannot be queued twice', () async {
      await store.db.insert(Tables.outbox, _entry('op-1').toMap());
      expect(() => store.db.insert(Tables.outbox, _entry('op-1').toMap()),
          throwsA(isA<DatabaseException>()));
    });
  });

  test('sync log row round trip', () async {
    final log = SyncLog(
      strategy: 'S2', startedAt: _t, durationMs: 950, recordCount: 500, changedCount: 50,
      bytesSent: 21000, bytesReceived: 4000, networkProfile: '4G', success: true,
    );
    final id = await store.db.insert(Tables.syncLog, log.toMap());
    final row = (await store.db.query(Tables.syncLog)).single;
    expect(SyncLog.fromMap(row).toMap(), {...log.toMap(), 'id': id});
  });

  group('meta', () {
    test('set, read and overwrite', () async {
      expect(await store.getMeta(MetaKeys.pullCursor), isNull);
      await store.setMeta(MetaKeys.pullCursor, '100');
      await store.setMeta(MetaKeys.pullCursor, '250');
      expect(await store.getMeta(MetaKeys.pullCursor), '250');
    });

    test('deviceId is made once and then kept', () async {
      final first = await store.deviceId();
      expect(first, hasLength(36));
      expect(await store.deviceId(), first);
    });
  });

  test('resetForExperiment empties records and outbox, keeps device id and log', () async {
    final device = await store.deviceId();
    await store.db.insert(Tables.mothers, _sample('mother').toMap());
    await store.db.insert(Tables.outbox, _entry('op-1').toMap());
    await store.db.insert(Tables.syncLog, SyncLog(
      strategy: 'S1', startedAt: _t, durationMs: 1, recordCount: 1, changedCount: 1,
      bytesSent: 1, bytesReceived: 1, networkProfile: 'none', success: true,
    ).toMap());
    await store.setMeta(MetaKeys.pullCursor, '9');

    await store.resetForExperiment();

    final counts = await store.tableCounts();
    expect(counts[Tables.mothers], 0);
    expect(counts[Tables.outbox], 0);
    expect(counts[Tables.syncLog], 1);
    expect(await store.getMeta(MetaKeys.pullCursor), isNull);
    expect(await store.deviceId(), device);
  });

  group('file database', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('lb_db_test'));
    tearDown(() => dir.delete(recursive: true));

    test('data is still there after closing and opening again', () async {
      final path = '${dir.path}/test.db';
      var s = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
      await s.db.insert(Tables.mothers, _sample('mother').toMap());
      final device = await s.deviceId();
      await s.close();

      s = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
      expect((await s.tableCounts())[Tables.mothers], 1);
      expect(await s.deviceId(), device);
      await s.close();
    });

    test('runMigrations applies only the missing steps, in order', () async {
      final db = await databaseFactoryFfi.openDatabase('${dir.path}/m.db');
      await db.execute('CREATE TABLE t (a TEXT)');
      final steps = [
        ['ALTER TABLE t ADD COLUMN b TEXT'], // v1 -> v2
        ['ALTER TABLE t ADD COLUMN c TEXT'], // v2 -> v3
      ];
      await AppDatabase.runMigrations(db, from: 2, to: 3, steps: steps);
      final cols = (await db.rawQuery('PRAGMA table_info(t)')).map((r) => r['name']);
      expect(cols, ['a', 'c']); // step 1 skipped, step 2 applied
      await db.close();
    });
  });
}
