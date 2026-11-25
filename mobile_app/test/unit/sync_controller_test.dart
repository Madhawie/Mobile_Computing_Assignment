import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/storage/app_database.dart';
import 'package:little_bloom/core/storage/schema.dart';
import 'package:little_bloom/core/sync/backoff.dart';
import 'package:little_bloom/core/sync/sync_controller.dart';
import 'package:little_bloom/core/sync/sync_engine.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_connectivity.dart';
import '../helpers/fake_sync_server.dart';

// Synthetic data only.
Mother _mother(int i) => Mother(
      id: '', version: 0, updatedAt: DateTime.utc(2026, 11, 26), deviceId: '',
      fullName: 'Test Mother $i', phone: '+947000005${i.toString().padLeft(2, '0')}', age: 25,
      address: 'x', areaId: 'glg-east', isPregnant: false,
    );

void main() {
  sqfliteFfiInit();
  late AppDatabase store;
  late AppRepositories repos;
  late FakeSyncServer server;
  late FakeConnectivity signal;
  late bool signedIn;
  late ValueNotifier<int> auth;
  late SyncController sync;

  setUp(() async {
    store = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    repos = AppRepositories(store);
    server = FakeSyncServer();
    signal = FakeConnectivity();
    signedIn = true;
    auth = ValueNotifier(0);
    sync = SyncController(
      engine: SyncEngine(store: store, api: server.client(), backoff: Backoff.none, sleep: (_) async {}),
      connectivity: signal,
      canSync: () => signedIn,
      signIn: auth,
      settle: const Duration(milliseconds: 20),
    );
  });
  tearDown(() async {
    sync.dispose();
    await store.close();
  });

  /// Real time passes until the controller is idle again.
  Future<void> idle() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    while (sync.syncing) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<int> logRows() async => (await repos.syncLogs.recent()).length;

  test('offline: nothing is sent, the changes wait', () async {
    await repos.mothers.create(_mother(0));
    await sync.start();
    await idle();
    expect((sync.online, sync.pending, server.pushCalls), (false, 1, 0));
  });

  test('signal comes back: sends by itself after the settle wait', () async {
    await sync.start();
    await repos.mothers.create(_mother(0));
    await repos.mothers.create(_mother(1));
    await sync.refresh();
    expect(sync.pending, 2);

    signal.set(true);
    await idle();
    expect((sync.pending, server.records.length), (0, 2));
    expect(sync.lastTrigger, SyncTrigger.reconnect);
    expect(sync.lastSyncAt, isNotNull);
    expect(await logRows(), 1);
  });

  test('signal flickers (back and gone again within the wait): no sync', () async {
    await repos.mothers.create(_mother(0));
    await sync.start();
    signal.set(true);
    signal.set(false);
    await idle();
    expect((server.pushCalls, sync.pending), (0, 1));
  });

  test('opened with signal: syncs once', () async {
    signal.online = true;
    await repos.mothers.create(_mother(0));
    await sync.start();
    await idle();
    expect((sync.lastTrigger, sync.pending), (SyncTrigger.opened, 0));
  });

  test('locked or signed out: never syncs; syncs once unlocked', () async {
    signedIn = false;
    signal.online = true;
    await repos.mothers.create(_mother(0));
    await sync.start();
    signal.set(false);
    signal.set(true);
    await idle();
    expect(server.pushCalls, 0);
    expect(await sync.sendNow(), isNull);

    signedIn = true;
    auth.value++; // PIN entered
    await idle();
    expect((sync.lastTrigger, sync.pending), (SyncTrigger.opened, 0));
  });

  test('automatic sending off: reconnect does nothing, Send now still works; setting is saved', () async {
    await sync.start();
    await sync.setAutoSync(false);
    expect(await store.getMeta(MetaKeys.autoSync), 'off');
    await repos.mothers.create(_mother(0));
    signal.set(true);
    await idle();
    expect(server.pushCalls, 0);

    final r = await sync.sendNow();
    expect((r!.success, sync.pending, sync.lastTrigger), (true, 0, SyncTrigger.button));
  });

  test('server unreachable although "online": the try is logged, changes stay', () async {
    server.dropBeforeSaving = 100;
    await repos.mothers.create(_mother(0));
    await sync.start();
    signal.set(true);
    await idle();
    expect((sync.lastResult!.success, sync.pending), (false, 1));
    expect((await repos.syncLogs.recent()).single.errorCode, 'NETWORK');
  });

  test('a refused change is counted apart from the waiting ones', () async {
    server.rejectEntity.add('mother');
    await repos.mothers.create(_mother(0));
    await sync.start();
    await sync.sendNow();
    expect((sync.pending, sync.failed), (0, 1));
  });
}
