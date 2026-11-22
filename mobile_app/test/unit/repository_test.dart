// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/storage/app_database.dart';
import 'package:little_bloom/core/storage/schema.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/data/repositories/repositories.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

// Synthetic test data only. A fixed clock keeps timestamps predictable.
final _now = DateTime.utc(2026, 11, 23, 10);
DateTime _clock() => _now;

Mother _draftMother({String id = '', String name = 'Test Mother', String area = 'area-1'}) => Mother(
      id: id, version: 0, updatedAt: _now, deviceId: '',
      fullName: name, phone: '+94700000001', age: 25, address: 'Test Road',
      areaId: area, isPregnant: true, gestationWeeks: 20,
    );

Mother _edit(Mother m, {String? name, int? weeks}) => Mother(
      id: m.id, version: m.version, updatedAt: m.updatedAt, deviceId: m.deviceId,
      fullName: name ?? m.fullName, phone: m.phone, age: m.age, address: m.address,
      areaId: m.areaId, isPregnant: m.isPregnant, gestationWeeks: weeks ?? m.gestationWeeks,
      dueDate: m.dueDate,
    );

/// Always returns the same id, to force a UNIQUE(operation_id) failure.
class _SameUuid extends Uuid {
  const _SameUuid();
  @override
  String v4({Map<String, dynamic>? options, V4Options? config}) => 'same-op-id';
}

void main() {
  sqfliteFfiInit();
  late AppDatabase store;
  late MotherRepository mothers;
  late OutboxRepository outbox;

  setUp(() async {
    store = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    mothers = MotherRepository(store, clock: _clock);
    outbox = OutboxRepository(store);
  });
  tearDown(() => store.close());

  Future<Map<String, dynamic>> rawRow(String id) async =>
      (await store.db.query(Tables.mothers, where: 'id = ?', whereArgs: [id])).single;

  group('create', () {
    test('saves the record as dirty, version 1, with this phone id', () async {
      final m = await mothers.create(_draftMother());
      expect(m.id, hasLength(36)); // new UUID
      expect(m.version, 1);
      expect(m.isDirty, isTrue);
      expect(m.deviceId, await store.deviceId());
      expect(m.updatedAt, _now);
      expect((await mothers.getById(m.id))!.fullName, 'Test Mother');
    });

    test('queues one upsert with baseVersion 0 and every field', () async {
      final m = await mothers.create(_draftMother());
      final rows = await outbox.pending();
      expect(rows, hasLength(1));
      final e = rows.single;
      expect(e.op, OutboxOp.upsert);
      expect(e.entity, 'mother');
      expect(e.recordId, m.id);
      expect(e.baseVersion, 0);
      expect(e.changedFields, containsAll(['fullName', 'phone', 'areaId']));
      expect(e.payload, m.toJson());
      expect(e.operationId, hasLength(36));
    });
  });

  group('update', () {
    test('bumps the version and lists only changed fields', () async {
      final m = await mothers.create(_draftMother());
      final u = await mothers.update(_edit(m, weeks: 22));
      expect(u.version, 2);
      expect(u.gestationWeeks, 22);
      final last = (await outbox.pending()).last;
      expect(last.changedFields, ['gestationWeeks']);
      expect(last.payload['gestationWeeks'], 22);
    });

    test('an edit that changes nothing is not queued', () async {
      final m = await mothers.create(_draftMother());
      final same = await mothers.update(_edit(m));
      expect(same.version, 1);
      expect(await outbox.pendingCount(), 1);
    });

    test('second offline edit counts the first one still queued', () async {
      final m = await mothers.create(_draftMother()); // base 0
      final a = await mothers.update(_edit(m, weeks: 21)); // base 0 + 1 queued = 1
      await mothers.update(_edit(a, name: 'Renamed')); // base 0 + 2 queued = 2
      expect((await outbox.pending()).map((e) => e.baseVersion), [0, 1, 2]);
    });

    test('after the server confirmed, base is the server version', () async {
      final m = await mothers.create(_draftMother());
      // What the sync engine will do after a push (Day 11):
      await outbox.remove([(await outbox.pending()).single.operationId]);
      await store.db.update(Tables.mothers, {'server_version': 1, 'is_dirty': 0},
          where: 'id = ?', whereArgs: [m.id]);

      await mothers.update(_edit(m, weeks: 25));
      expect((await outbox.pending()).single.baseVersion, 1);
      expect((await rawRow(m.id))['server_version'], 1); // kept by update
    });

    test('a deleted record cannot be edited', () async {
      final m = await mothers.create(_draftMother());
      await mothers.softDelete(m.id);
      expect(() => mothers.update(_edit(m, weeks: 30)), throwsStateError);
    });
  });

  group('soft delete', () {
    test('keeps a tombstone and queues a delete', () async {
      final m = await mothers.create(_draftMother());
      await mothers.softDelete(m.id);

      final row = await rawRow(m.id);
      expect(row['deleted'], 1);
      expect(row['version'], 2);
      expect(row['is_dirty'], 1);

      final e = (await outbox.pending()).last;
      expect(e.op, OutboxOp.delete);
      expect(e.changedFields, ['deleted']);
      expect(e.payload['deleted'], true);
    });

    test('deleted records are hidden from reads unless asked for', () async {
      final m = await mothers.create(_draftMother());
      await mothers.softDelete(m.id);
      expect(await mothers.getById(m.id), isNull);
      expect(await mothers.getById(m.id, includeDeleted: true), isNotNull);
      expect(await mothers.inArea('area-1'), isEmpty);
    });

    test('deleting twice queues only one delete', () async {
      final m = await mothers.create(_draftMother());
      await mothers.softDelete(m.id);
      await mothers.softDelete(m.id);
      expect((await outbox.pending()).where((e) => e.op == OutboxOp.delete), hasLength(1));
    });
  });

  group('outbox is written on every change', () {
    test('5 changes → 5 outbox rows, oldest first, unique operation ids', () async {
      final a = await mothers.create(_draftMother(name: 'A'));
      final b = await mothers.create(_draftMother(name: 'B'));
      await mothers.update(_edit(a, weeks: 30));
      await mothers.update(_edit(b, name: 'B2'));
      await mothers.softDelete(b.id);

      final rows = await outbox.pending();
      expect(rows.map((e) => e.op.name), ['upsert', 'upsert', 'upsert', 'upsert', 'delete']);
      expect(rows.map((e) => e.operationId).toSet(), hasLength(5));
      expect(await outbox.pendingCount(), 5);
    });

    test('works the same for every record type', () async {
      final m = await mothers.create(_draftMother());
      final children = ChildRepository(store, clock: _clock);
      final c = await children.create(Child(
          id: '', version: 0, updatedAt: _now, deviceId: '', motherId: m.id,
          name: 'Test Baby', sex: Sex.girl, dateOfBirth: DateTime(2026, 6, 1), birthWeightKg: 2.9));
      await GrowthRepository(store, clock: _clock).create(GrowthMeasurement(
          id: '', version: 0, updatedAt: _now, deviceId: '', childId: c.id,
          measuredOn: DateTime(2026, 11, 23), weightKg: 7.0));
      await VaccinationRepository(store, clock: _clock).create(Vaccination(
          id: '', version: 0, updatedAt: _now, deviceId: '', childId: c.id,
          vaccine: 'OPV', dose: 1, givenOn: DateTime(2026, 8, 1)));
      await MaternalVisitRepository(store, clock: _clock).create(MaternalVisit(
          id: '', version: 0, updatedAt: _now, deviceId: '', motherId: m.id,
          visitDate: DateTime(2026, 11, 23), gestationWeeks: 20, weightKg: 60,
          bpSystolic: 120, bpDiastolic: 80));

      expect((await outbox.pending()).map((e) => e.entity),
          ['mother', 'child', 'growthMeasurement', 'vaccination', 'maternalVisit']);
    });

    test('if the outbox write fails, the record is not saved either', () async {
      final repo = MotherRepository(store, clock: _clock, uuid: const _SameUuid());
      await repo.create(_draftMother(id: 'm-1'));
      // Second change gets the same operation id → UNIQUE fails → rollback.
      await expectLater(repo.create(_draftMother(id: 'm-2')), throwsA(isA<DatabaseException>()));
      expect(await mothers.getById('m-2'), isNull);
      expect(await outbox.pendingCount(), 1);
    });
  });

  group('OutboxRepository', () {
    test('counts attempts, removes confirmed, keeps failed apart', () async {
      for (final n in ['A', 'B', 'C']) {
        await mothers.create(_draftMother(name: n));
      }
      final ids = (await outbox.pending()).map((e) => e.operationId).toList();

      await outbox.recordAttempt(ids);
      await outbox.recordAttempt(ids.sublist(1));
      expect((await outbox.pending()).map((e) => e.attempts), [1, 2, 2]);

      expect(await outbox.remove([ids[0]]), 1);
      await outbox.markFailed(ids[1], 'INVALID_FIELD');

      expect((await outbox.pending()).map((e) => e.operationId), [ids[2]]);
      final failed = (await outbox.failed()).single;
      expect(failed.operationId, ids[1]);
      expect(failed.lastError, 'INVALID_FIELD');
    });
  });

  group('screen queries', () {
    test('area register is A–Z; search finds name or phone', () async {
      await mothers.create(_draftMother(name: 'nimali'));
      await mothers.create(_draftMother(name: 'Anoma'));
      await mothers.create(_draftMother(name: 'Other Area', area: 'area-2'));
      expect((await mothers.inArea('area-1')).map((m) => m.fullName), ['Anoma', 'nimali']);
      expect(await mothers.search('anom'), hasLength(1));
      expect(await mothers.search('0000001'), hasLength(3));
    });

    test('growth points come oldest first for the chart', () async {
      final growth = GrowthRepository(store, clock: _clock);
      for (final d in [DateTime(2026, 9, 1), DateTime(2026, 7, 1), DateTime(2026, 8, 1)]) {
        await growth.create(GrowthMeasurement(
            id: '', version: 0, updatedAt: _now, deviceId: '', childId: 'c-1',
            measuredOn: d, weightKg: 7));
      }
      expect((await growth.forChild('c-1')).map((g) => g.measuredOn.month), [7, 8, 9]);
    });
  });
}
