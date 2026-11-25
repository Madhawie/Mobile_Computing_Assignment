import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/storage/app_database.dart';
import 'package:little_bloom/core/storage/schema.dart';
import 'package:little_bloom/core/sync/backoff.dart';
import 'package:little_bloom/core/sync/outbox_pusher.dart';
import 'package:little_bloom/core/sync/puller.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:little_bloom/features/phm/conflicts/conflicts_view_model.dart';
import 'package:little_bloom/core/network/api_exception.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_sync_server.dart';

// Synthetic data only.
Map<String, dynamic> serverMother(String id, {String name = 'Test Mother', bool deleted = false}) => {
      'id': id, 'updatedAt': '2026-11-26T08:00:00.000Z', 'deviceId': 'clinic', 'deleted': deleted,
      'fullName': name, 'phone': '+94700000300', 'age': 28, 'address': 'Clinic Road', 'areaId': 'glg-east',
      'isPregnant': false, 'gestationWeeks': null, 'dueDate': null,
    };

void main() {
  sqfliteFfiInit();
  late AppDatabase store;
  late AppRepositories repos;
  late FakeSyncServer server;

  setUp(() async {
    store = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    repos = AppRepositories(store);
    server = FakeSyncServer();
  });
  tearDown(() => store.close());

  Puller puller({int pageSize = 500, int overlap = 50}) =>
      Puller(store: store, api: server.client(), pageSize: pageSize, overlap: overlap);
  OutboxPusher pusher() =>
      OutboxPusher(store: store, api: server.client(), backoff: Backoff.none, sleep: (_) async {});
  Future<Map<String, Object?>> row(String id) async =>
      (await store.db.query(Tables.mothers, where: 'id = ?', whereArgs: [id])).single;

  group('pull', () {
    test('first pull downloads everything, clean, with server versions; cursor saved', () async {
      for (var i = 0; i < 3; i++) {
        server.serverWrite('mother', serverMother('m$i'));
      }
      final r = await puller().pullAll();
      expect((r.success, r.applied, r.cursor), (true, 3, 3));
      expect(await store.getMeta(MetaKeys.pullCursor), '3');
      final m = await row('m0');
      expect((m['is_dirty'], m['server_version'], m['full_name']), (0, 1, 'Test Mother'));
    });

    test('pages until hasMore is false', () async {
      for (var i = 0; i < 5; i++) {
        server.serverWrite('mother', serverMother('m$i'));
      }
      final r = await puller(pageSize: 2).pullAll();
      expect((r.pages, r.applied, r.cursor), (3, 5, 5));
    });

    test('next pull starts before the cursor (overlap); repeats change nothing', () async {
      for (var i = 0; i < 4; i++) {
        server.serverWrite('mother', serverMother('m$i'));
      }
      await puller().pullAll();
      server.serverWrite('mother', serverMother('m1', name: 'Changed at clinic'));
      final r = await puller(overlap: 50).pullAll();
      expect(r.stale, 3); // m0, m2, m3 again: already have them
      expect(r.applied, 1);
      expect((await row('m1'))['full_name'], 'Changed at clinic');
      expect(await store.getMeta(MetaKeys.pullCursor), '5'); // never moves back
    });

    test("the phone's unsent edit is kept, not overwritten by the pull", () async {
      server.serverWrite('mother', serverMother('m1'));
      await puller().pullAll();
      final local = (await repos.mothers.getById('m1'))!;
      await repos.mothers.update(Mother(
        id: local.id, version: local.version, updatedAt: local.updatedAt, deviceId: local.deviceId,
        fullName: 'PHM edit', phone: local.phone, age: local.age, address: local.address,
        areaId: local.areaId, isPregnant: false,
      ));
      server.serverWrite('mother', serverMother('m1', name: 'Clinic edit'));

      final r = await puller().pullAll();
      expect(r.keptLocal, 1);
      expect((await repos.mothers.getById('m1'))!.fullName, 'PHM edit');
    });

    test('S1 full pull ignores the cursor', () async {
      server.serverWrite('mother', serverMother('m1'));
      await puller().pullAll();
      final r = await puller().pullAll(full: true);
      expect(r.received, 1);
    });

    test('connection drops on page 2: page 1 stays, next pull continues from there', () async {
      for (var i = 0; i < 4; i++) {
        server.serverWrite('mother', serverMother('m$i'));
      }
      server
        ..pullDrops = 1
        ..pullFailAfterPages = 1;
      final cut = await puller(pageSize: 2, overlap: 0).pullAll();
      expect((cut.success, cut.errorCode, cut.applied), (false, 'NETWORK', 2));
      expect(await store.getMeta(MetaKeys.pullCursor), '2');

      final again = await puller(pageSize: 2, overlap: 0).pullAll();
      expect((again.success, again.applied), (true, 2));
      expect((await repos.mothers.list()).length, 4);
    });

    test('a record the phone cannot read is skipped, the rest is applied', () async {
      server.serverWrite('mother', serverMother('m1'));
      server.serverWrite('mother', {'id': 'broken', 'fullName': 'No other fields'});
      final r = await puller().pullAll();
      expect((r.applied, r.invalid), (1, 1));
    });
  });

  group('tombstones not resurrected', () {
    test('deleted on the phone, older copy pulled before the push: stays deleted', () async {
      server.serverWrite('mother', serverMother('m1'));
      await puller().pullAll();
      await repos.mothers.softDelete('m1'); // offline delete, not sent yet
      server.serverWrite('mother', serverMother('m1', name: 'Older server copy'));

      await puller().pullAll();
      expect(await repos.mothers.getById('m1'), isNull);
      expect((await row('m1'))['deleted'], 1);
    });

    test('after the delete is pushed, pulls (incl. the overlap) never bring it back', () async {
      server.serverWrite('mother', serverMother('m1'));
      await puller().pullAll();
      await repos.mothers.softDelete('m1');
      expect((await pusher().pushAll()).applied, 1);
      expect(server.records[('mother', 'm1')]!['deleted'], true);

      await puller().pullAll();
      await puller().pullAll(full: true);
      expect(await repos.mothers.getById('m1'), isNull);
    });

    test('deleted on another device: the tombstone hides it here too', () async {
      server.serverWrite('mother', serverMother('m1'));
      await puller().pullAll();
      server.serverWrite('mother', serverMother('m1', deleted: true));
      final r = await puller().pullAll();
      expect(r.tombstones, 1);
      expect(await repos.mothers.getById('m1'), isNull);
      expect(await repos.mothers.inArea('glg-east'), isEmpty);
    });
  });

  test('schema upgrade v1 → v2 adds the conflicts table and keeps the data', () async {
    final dir = await Directory.systemTemp.createTemp('lb_migrate');
    final path = '${dir.path}/old.db';
    final v1 = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(version: 1, onCreate: (db, _) async {
      for (final sql in schemaV1) {
        await db.execute(sql);
      }
    }));
    await v1.insert(Tables.meta, {'key': MetaKeys.pullCursor, 'value': '42'});
    await v1.close();

    final upgraded = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
    expect(await upgraded.db.getVersion(), 2);
    expect(await upgraded.getMeta(MetaKeys.pullCursor), '42');
    expect(await upgraded.db.query(Tables.conflicts), isEmpty);
    await upgraded.close();
    await dir.delete(recursive: true);
  });

  group('Check a record', () {
    setUp(() {
      server.serverWrite('mother', {...serverMother('m1'), 'gestationWeeks': 24, 'isPregnant': true});
      server.conflicts.add({
        'id': 'c1', 'entity': 'mother', 'recordId': 'm1', 'kind': 'sameField', 'status': 'open',
        'createdAt': '2026-11-26T09:00:00Z', 'resolvedAt': null, 'resolution': null,
        'fields': [
          {'field': 'gestationWeeks', 'kept': 24, 'lost': 22, 'lostSide': 'server', 'lostDeviceId': 'clinic'}
        ],
      });
    });

    test('lists conflicts with the record name and keeps a copy for offline', () async {
      await puller().pullAll();
      final vm = ConflictsViewModel(repos, server.client());
      await vm.load();
      expect(vm.items.single.recordLabel, 'Test Mother');
      expect(vm.items.single.conflict.fields.single.lost, 22);

      server.conflictsOffline = true;
      final offlineVm = ConflictsViewModel(repos, server.client());
      await offlineVm.load();
      expect((offlineVm.offline, offlineVm.items.length), (true, 1));
      expect(await repos.conflicts.openCount(), 1);
    });

    test('"use the other value" writes it back and clears the conflict', () async {
      await puller().pullAll();
      final vm = ConflictsViewModel(repos, server.client());
      await vm.load();
      await vm.decide(vm.items.single.conflict, keepCurrent: false);

      expect(vm.items, isEmpty);
      expect((await repos.mothers.getById('m1'))!.gestationWeeks, 22);
      expect(await repos.conflicts.openCount(), 0);
    });

    test('deciding with no signal fails and keeps the conflict open', () async {
      final vm = ConflictsViewModel(repos, server.client());
      await vm.load();
      server.conflictsOffline = true;
      await expectLater(vm.decide(vm.items.single.conflict, keepCurrent: true), throwsA(isA<ApiFailure>()));
      expect(await repos.conflicts.openCount(), 1);
    });
  });
}
