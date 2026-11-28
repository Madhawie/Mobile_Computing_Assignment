import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/sync/backoff.dart';
import 'package:little_bloom/core/sync/sync_controller.dart';
import 'package:little_bloom/core/sync/sync_engine.dart';
import 'package:little_bloom/core/theme/app_theme.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:little_bloom/features/phm/sync/sync_screen.dart';
import 'package:little_bloom/features/phm/sync/sync_view_model.dart';
import 'package:little_bloom/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_connectivity.dart';
import '../helpers/fake_sync_server.dart';
import '../helpers/test_app.dart';

// Synthetic data only.
Mother _mother() => Mother(
      id: '', version: 0, updatedAt: DateTime.utc(2026, 11, 26), deviceId: '',
      fullName: 'Test Mother', phone: '+94700000601', age: 25, address: 'x', areaId: 'glg-east', isPregnant: true,
    );

void main() {
  late AppRepositories repos;
  late FakeSyncServer server;
  late SyncController sync;

  Future<void> open(WidgetTester tester) async {
    repos = await openTestRepos(tester);
    server = FakeSyncServer();
    sync = SyncController(
      engine: SyncEngine(store: repos.store, api: server.client(), backoff: Backoff.none, sleep: (_) async {}),
      connectivity: FakeConnectivity(), // offline: no automatic sync during the test
      canSync: () => true,
    );
    late SyncViewModel vm;
    await tester.runAsync(() async {
      final m = await repos.mothers.create(_mother());
      await repos.children.create(Child(
        id: '', version: 0, updatedAt: DateTime.utc(2026, 11, 26), deviceId: '', motherId: m.id,
        name: 'Test Baby', sex: Sex.girl, dateOfBirth: DateTime(2026, 5, 1), birthWeightKg: 3.1,
      ));
      await sync.start();
      vm = SyncViewModel(repos, sync);
      await vm.load();
    });
    addTearDown(() {
      vm.dispose();
      sync.dispose();
    });

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sync),
        ChangeNotifierProvider.value(value: vm),
      ],
      child: MaterialApp(
        theme: AppTheme.forRole(null),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SyncScreen()),
      ),
    ));
    await tester.pump();
  }

  testWidgets('offline: shows what waits, newest first, with names', (tester) async {
    await open(tester);
    expect(find.text('You are offline'), findsOneWidget);
    expect(find.text('2 changes waiting to send'), findsOneWidget);
    expect(find.text('Waiting to send · 2'), findsOneWidget);
    expect(find.text('Child · Test Baby'), findsOneWidget);
    expect(find.text('Mother · Test Mother'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Child · Test Baby')).dy,
      lessThan(tester.getTopLeft(find.text('Mother · Test Mother')).dy),
    );
  });

  testWidgets('Send now: sends everything and the list empties', (tester) async {
    await open(tester);
    await tester.tap(find.text('Send now'));
    await settleDb(tester);

    expect(find.text('Everything is sent'), findsOneWidget);
    expect(find.text('Sent 2, received 0.'), findsOneWidget);
    expect(find.textContaining('Waiting to send'), findsNothing);
    expect(server.records, hasLength(2));
  });

  testWidgets('server unreachable: says the changes are safe and keeps them', (tester) async {
    await open(tester);
    server.dropBeforeSaving = 100;
    await tester.tap(find.text('Send now'));
    // 6 tries (first + 5 retries) take more database round trips.
    for (var i = 0; i < 50 && (sync.syncing || sync.lastResult == null); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    await settleDb(tester);
    expect(find.textContaining('Your changes are safe on this phone'), findsOneWidget);
    expect(find.text('Waiting to send · 2'), findsOneWidget);
  });

  testWidgets('the automatic switch turns off and stays off', (tester) async {
    await open(tester);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
    await tester.tap(find.text('Send automatically'));
    await settleDb(tester);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    expect(await tester.runAsync(() => repos.store.getMeta('auto_sync')), 'off');
  });
}
