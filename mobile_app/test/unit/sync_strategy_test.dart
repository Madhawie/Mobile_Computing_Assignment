import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/storage/app_database.dart';
import 'package:little_bloom/core/storage/schema.dart';
import 'package:little_bloom/core/sync/backoff.dart';
import 'package:little_bloom/core/sync/sync_engine.dart';
import 'package:little_bloom/core/sync/sync_strategy.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_sync_server.dart';

// Synthetic data only.
Mother _mother(int i) => Mother(
      id: '', version: 0, updatedAt: DateTime.utc(2026, 11, 26), deviceId: '',
      fullName: 'Test Mother $i', phone: '+947000004${i.toString().padLeft(2, '0')}', age: 25,
      address: 'Old Road', areaId: 'glg-east', isPregnant: false,
    );

Mother _withAddress(Mother m, String address) => Mother(
      id: m.id, version: m.version, updatedAt: m.updatedAt, deviceId: m.deviceId, fullName: m.fullName,
      phone: m.phone, age: m.age, address: address, areaId: m.areaId, isPregnant: m.isPregnant,
    );

void main() {
  sqfliteFfiInit();
  late AppDatabase store;
  late AppRepositories repos;
  late FakeSyncServer server;
  late SyncEngine engine;

  setUp(() async {
    store = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    repos = AppRepositories(store);
    server = FakeSyncServer();
    engine = SyncEngine(store: store, api: server.client(), backoff: Backoff.none, sleep: (_) async {});
  });
  tearDown(() => store.close());

  /// 10 mothers, all synced once with S3, then [edited] of them changed offline.
  Future<List<Mother>> syncedThenEdit(int edited) async {
    final mothers = [for (var i = 0; i < 10; i++) await repos.mothers.create(_mother(i))];
    await engine.syncNow(strategy: const VersionedDeltaSync());
    for (final m in mothers.take(edited)) {
      await repos.mothers.update(_withAddress((await repos.mothers.getById(m.id))!, 'New Road'));
    }
    server.changesReceived = 0;
    return mothers;
  }

  group('strategy selection', () {
    test('S3 by default; the choice is saved; unknown names fall back to S3', () async {
      expect((await engine.strategy()).name, 'S3');
      await engine.setStrategy(const FullSync());
      expect((await engine.strategy()).name, 'S1');
      expect(await store.getMeta(MetaKeys.syncStrategy), 'S1');

      await store.setMeta(MetaKeys.syncStrategy, 'S9');
      expect((await engine.strategy()).name, 'S3');
      expect(SyncStrategy.all.map((s) => s.name), ['S1', 'S2', 'S3']);
    });

    test('the saved strategy is the one sent to the server', () async {
      await repos.mothers.create(_mother(0));
      await engine.setStrategy(const DeltaSync());
      final r = (await engine.syncNow())!;
      expect((server.lastStrategy, r.log.strategy), ('S2', 'S2'));
    });

    test('S1 sends every record, even unchanged ones', () async {
      await syncedThenEdit(2);
      final r = (await engine.syncNow(strategy: const FullSync()))!;
      expect(server.changesReceived, 10);
      expect((r.log.recordCount, r.log.changedCount), (10, 10));
      expect(await repos.outbox.pendingCount(), 0); // the 2 edits went with it
      expect((await store.db.query(Tables.mothers, where: 'is_dirty = 1')), isEmpty);
    });

    test('S2 and S3 send only the changed records', () async {
      for (final s in [const DeltaSync(), const VersionedDeltaSync()]) {
        await store.resetForExperiment();
        server = FakeSyncServer();
        engine = SyncEngine(store: store, api: server.client(), backoff: Backoff.none, sleep: (_) async {});
        await syncedThenEdit(2);
        final r = (await engine.syncNow(strategy: s))!;
        expect((server.changesReceived, r.log.changedCount, r.log.recordCount), (2, 2, 10), reason: s.name);
      }
    });

    test('S1 downloads everything again; S2/S3 only what is new', () async {
      engine = SyncEngine(store: store, api: server.client(), overlap: 0, backoff: Backoff.none, sleep: (_) async {});
      await syncedThenEdit(0);
      final s1 = (await engine.syncNow(strategy: const FullSync()))!;
      final s3 = (await engine.syncNow(strategy: const VersionedDeltaSync()))!;
      expect(s1.pull!.received, 10);
      expect(s3.pull!.received, 0); // nothing new since the cursor
      expect(s1.log.bytesSent + s1.log.bytesReceived, greaterThan(s3.log.bytesSent + s3.log.bytesReceived));
    });

    test('S1 keeps an edit made while it was syncing for the next run', () async {
      final mothers = await syncedThenEdit(0);
      // The edit lands after S1 took its snapshot: its outbox row has a
      // higher id, so it is not "covered" and must stay for the next sync.
      server.duringPush = () async =>
          repos.mothers.update(_withAddress((await repos.mothers.getById(mothers.first.id))!, 'During sync'));
      await engine.syncNow(strategy: const FullSync());
      expect(await repos.outbox.pendingCount(), 1);
      expect((await repos.mothers.getById(mothers.first.id))!.address, 'During sync');
    });

    test('same record edited on the server: S2 loses that edit, S3 flags it', () async {
      for (final s in [const DeltaSync(), const VersionedDeltaSync()]) {
        await store.resetForExperiment();
        server = FakeSyncServer();
        engine = SyncEngine(store: store, api: server.client(), backoff: Backoff.none, sleep: (_) async {});
        final m = (await syncedThenEdit(1)).first;
        server.conflictOn[m.id] = {'address': 'Clinic Road'};
        final r = (await engine.syncNow(strategy: s))!;
        if (s.detectsConflicts) {
          expect((r.log.conflicts, server.lostUpdates), (1, 0), reason: 'S3');
        } else {
          expect((r.log.conflicts, server.lostUpdates), (0, 1), reason: 'S2');
        }
      }
    });
  });

  group('sync logging', () {
    test('a successful sync writes one row with every measure', () async {
      await repos.mothers.create(_mother(0));
      server.dropAfterSaving = 1; // one retry, answered as duplicate
      final api = server.client()..networkProfile = '3G';
      engine = SyncEngine(store: store, api: api, backoff: Backoff.none, sleep: (_) async {});
      final r = (await engine.syncNow(runLabel: 'E4-test-run1'))!;

      final log = (await repos.syncLogs.recent()).single;
      expect(log.id, isNotNull);
      expect((log.strategy, log.success, log.networkProfile, log.runLabel), ('S3', true, '3G', 'E4-test-run1'));
      expect((log.recordCount, log.changedCount, log.duplicates, log.retries), (1, 1, 1, 1));
      expect(log.bytesSent, greaterThan(0));
      expect(log.bytesReceived, greaterThan(0));
      expect(log.durationMs, r.log.durationMs);
      expect(await store.getMeta(MetaKeys.lastSyncAt), isNotNull);
    });

    test('a failed sync is logged too, with its error, and skips the pull', () async {
      await repos.mothers.create(_mother(0));
      server.dropBeforeSaving = 100;
      final r = (await engine.syncNow())!;
      expect((r.success, r.log.errorCode, r.pull), (false, 'NETWORK', null));
      final log = (await repos.syncLogs.recent()).single;
      expect((log.success, log.errorCode, log.retries), (false, 'NETWORK', 5));
      expect(await store.getMeta(MetaKeys.lastSyncAt), isNull);
    });

    test('a second sync while one runs is refused and not logged', () async {
      await repos.mothers.create(_mother(0));
      final first = engine.syncNow();
      expect(await engine.syncNow(), isNull);
      await first;
      expect(await repos.syncLogs.recent(), hasLength(1));
    });

    test('CSV export: header plus one line per run, oldest first', () async {
      await engine.syncNow(strategy: const FullSync(), runLabel: 'E1-50-run1');
      await engine.syncNow(strategy: const DeltaSync(), runLabel: 'label, with comma');
      final lines = (await repos.syncLogs.toCsv()).trim().split('\n');
      expect(lines.first, SyncLog.csvHeader.join(','));
      expect(lines, hasLength(3));
      expect(lines[1], startsWith('S1,'));
      expect(lines[2], endsWith('"label, with comma"'));
    });

    test('logs survive an experiment reset', () async {
      await engine.syncNow();
      await store.resetForExperiment();
      expect(await repos.syncLogs.recent(), hasLength(1));
    });
  });
}
