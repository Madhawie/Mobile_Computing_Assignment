import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/sync/puller.dart';
import 'package:little_bloom/core/theme/app_theme.dart';
import 'package:little_bloom/features/phm/conflicts/conflicts_screen.dart';
import 'package:little_bloom/features/phm/conflicts/conflicts_view_model.dart';
import 'package:little_bloom/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_sync_server.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('shows both values, decides, and says nothing left to check', (tester) async {
    final repos = await openTestRepos(tester);
    final server = FakeSyncServer()
      ..serverWrite('mother', {
        'id': 'm1', 'updatedAt': '2026-11-26T08:00:00.000Z', 'deviceId': 'clinic', 'deleted': false,
        'fullName': 'Test Mother', 'phone': '+94700000301', 'age': 28, 'address': 'x', 'areaId': 'glg-east',
        'isPregnant': true, 'gestationWeeks': 24, 'dueDate': null,
      })
      ..conflicts.add({
        'id': 'c1', 'entity': 'mother', 'recordId': 'm1', 'kind': 'sameField', 'status': 'open',
        'createdAt': '2026-11-26T09:00:00Z', 'resolvedAt': null, 'resolution': null,
        'fields': [
          {'field': 'gestationWeeks', 'kept': 24, 'lost': 22, 'lostSide': 'server', 'lostDeviceId': 'clinic'}
        ],
      });
    final vm = ConflictsViewModel(repos, server.client());
    await tester.runAsync(() async {
      await Puller(store: repos.store, api: server.client()).pullAll();
      await vm.load();
    });

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: vm,
      child: MaterialApp(
        theme: AppTheme.forRole(null),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ConflictsScreen(),
      ),
    ));
    await tester.pump();

    expect(find.text('Test Mother'), findsOneWidget);
    expect(find.text('Weeks pregnant'), findsOneWidget);
    expect(find.text('Now: 24'), findsOneWidget);
    expect(find.text('Other value (another phone): 22'), findsOneWidget);

    await tester.tap(find.text('Keep as it is'));
    await settleDb(tester);
    expect(find.text('Nothing to check. All records agree.'), findsOneWidget);
  });
}
