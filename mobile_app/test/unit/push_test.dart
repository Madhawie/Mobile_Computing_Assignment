import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/storage/app_database.dart';
import 'package:little_bloom/core/storage/schema.dart';
import 'package:little_bloom/core/sync/backoff.dart';
import 'package:little_bloom/core/sync/outbox_pusher.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_sync_server.dart';

// Synthetic data only.
Mother _mother(int i) => Mother(
      id: '', version: 0, updatedAt: DateTime.utc(2026, 11, 26), deviceId: '',
      fullName: 'Test Mother $i', phone: '+947000002${i.toString().padLeft(2, '0')}', age: 25,
      address: 'x', areaId: 'glg-east', isPregnant: false,
    );

void main() {
  sqfliteFfiInit();
  late AppDatabase store;
  late AppRepositories repos;
  late FakeSyncServer server;
  late List<Duration> waits;

  setUp(() async {
    store = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    repos = AppRepositories(store);
    server = FakeSyncServer();
    waits = [];
  });
  tearDown(() => store.close());

  OutboxPusher pusher({int batchSize = 200, Backoff backoff = const Backoff(jitter: false)}) => OutboxPusher(
        store: store,
        api: server.client(),
        batchSize: batchSize,
        backoff: backoff,
        sleep: (d) async => waits.add(d), // no real waiting in tests
      );

  Future<List<Mother>> addMothers(int n) async => [for (var i = 0; i < n; i++) await repos.mothers.create(_mother(i))];

  Future<Map<String, Object?>> row(String id) async =>
      (await store.db.query(Tables.mothers, where: 'id = ?', whereArgs: [id])).single;

  group('S3 push', () {
    test('every change applied: outbox empty, records clean with the server version', () async {
      final mothers = await addMothers(3);
      final r = await pusher().pushAll();

      expect((r.success, r.sent, r.applied, r.batches), (true, 3, 3, 1));
      expect(await repos.outbox.pendingCount(), 0);
      final first = await row(mothers.first.id);
      expect((first['is_dirty'], first['server_version'], first['version']), (0, 1, 1));
      expect(server.records, hasLength(3));
    });

    test('create then edit offline: sent in order, base 0 then 1, server ends at version 2', () async {
      final m = (await addMothers(1)).single;
      await repos.mothers.update(Mother(
        id: m.id, version: m.version, updatedAt: m.updatedAt, deviceId: m.deviceId, fullName: 'Renamed',
        phone: m.phone, age: m.age, address: m.address, areaId: m.areaId, isPregnant: false,
      ));
      final r = await pusher().pushAll();
      expect(r.applied, 2);
      expect(server.records[('mother', m.id)]!['fullName'], 'Renamed');
      final local = await row(m.id);
      expect((local['server_version'], local['is_dirty']), (2, 0));
    });

    test('works in batches of the given size', () async {
      await addMothers(9);
      final r = await pusher(batchSize: 4).pushAll();
      expect((r.batches, r.applied, server.pushCalls), (3, 9, 3));
    });

    test('rejected change stays, marked failed; the others go through', () async {
      final m = (await addMothers(1)).single;
      await repos.children.create(Child(
        id: '', version: 0, updatedAt: DateTime.utc(2026, 11, 26), deviceId: '', motherId: m.id,
        name: 'Test Baby', sex: Sex.boy, dateOfBirth: DateTime(2026, 1, 1), birthWeightKg: 3,
      ));
      server.rejectEntity.add('child');
      final r = await pusher().pushAll();

      expect((r.applied, r.rejected), (1, 1));
      expect(await repos.outbox.pendingCount(), 0);
      final failed = (await repos.outbox.failed()).single;
      expect((failed.entity, failed.lastError), ('child', 'INVALID_FIELD'));
    });

    test('flagged conflict: phone takes the server merged record, counts the conflict', () async {
      final m = (await addMothers(1)).single;
      server.conflictOn[m.id] = {'address': 'Changed at the clinic'};
      final r = await pusher().pushAll();

      expect((r.flagged, r.conflicts), (1, 1));
      expect(r.conflictIds, ['conflict-${m.id}']);
      final local = await row(m.id);
      expect((local['address'], local['is_dirty']), ('Changed at the clinic', 0));
    });

    test('a second push while one is running returns BUSY at once', () async {
      await addMothers(2);
      final p = pusher();
      final first = p.pushAll();
      final second = await p.pushAll();
      expect(second.errorCode, 'BUSY');
      expect((await first).applied, 2);
    });
  });

  group('retries never duplicate', () {
    test('connection drops AFTER the server saved: retry gets "duplicate", nothing saved twice', () async {
      await addMothers(5);
      server.dropAfterSaving = 1;
      final r = await pusher().pushAll();

      expect(r.success, isTrue);
      expect(r.retries, 1);
      expect(r.duplicates, 5); // the server already had them
      expect(r.applied, 0);
      expect(server.records, hasLength(5)); // no copies
      expect(server.records.values.every((rec) => rec['version'] == 1), isTrue);
      expect(await repos.outbox.pendingCount(), 0); // nothing lost on the phone
    });

    test('drops before the server saved: retried until it works', () async {
      await addMothers(3);
      server.dropBeforeSaving = 2;
      final r = await pusher().pushAll();
      expect((r.success, r.retries, r.applied), (true, 2, 3));
      expect(waits, [const Duration(seconds: 1), const Duration(seconds: 2)]); // backoff 1 s, 2 s
    });

    test('server busy (503) is retried', () async {
      await addMothers(2);
      server.busy = 1;
      final r = await pusher().pushAll();
      expect((r.retries, r.applied), (1, 2));
    });

    test('still no signal after 5 retries: stops, keeps every row, counts attempts', () async {
      await addMothers(3);
      server.dropBeforeSaving = 100;
      final r = await pusher().pushAll();

      expect((r.success, r.errorCode, r.retries), (false, 'NETWORK', 5));
      final rows = await repos.outbox.pending();
      expect(rows, hasLength(3)); // kept for the next sync
      expect(rows.every((e) => e.attempts == 6), isTrue); // first try + 5 retries
      expect(waits.map((d) => d.inSeconds), [1, 2, 4, 8, 16]);

      server.dropBeforeSaving = 0; // signal is back
      final again = await pusher().pushAll();
      expect((again.applied, server.records.length), (3, 3));
    });

    test('4xx is not retried', () async {
      await addMothers(2);
      server.badRequest = true;
      final r = await pusher().pushAll();
      expect((r.errorCode, r.retries, server.pushCalls), ('VALIDATION_FAILED', 0, 1));
      expect(await repos.outbox.pendingCount(), 2);
    });

    test('413 batch too large: the batch is halved until it fits', () async {
      await addMothers(7);
      server.maxBatch = 3;
      final r = await pusher(batchSize: 7).pushAll();
      expect((r.success, r.applied, r.retries), (true, 7, 0));
      expect(server.records, hasLength(7));
    });

    test('two drops in a row at random points: still exactly one copy each', () async {
      await addMothers(10);
      server.dropAfterSaving = 1;
      server.dropBeforeSaving = 1;
      final r = await pusher(batchSize: 4).pushAll();
      expect(r.success, isTrue);
      expect(server.records, hasLength(10));
      expect(server.processed, hasLength(10));
      expect(await repos.outbox.pendingCount(), 0);
    });
  });

  group('Backoff', () {
    test('doubles from 1 s and stops at 60 s', () {
      const b = Backoff(jitter: false);
      expect([for (var i = 1; i <= 8; i++) b.delay(i).inSeconds], [1, 2, 4, 8, 16, 32, 60, 60]);
    });

    test('jitter waits between half and all of the delay', () {
      const b = Backoff();
      final random = math.Random(1);
      for (var i = 0; i < 50; i++) {
        final d = b.delay(4, random).inMilliseconds; // 8 s
        expect(d, inInclusiveRange(4000, 8000));
      }
    });
  });
}
