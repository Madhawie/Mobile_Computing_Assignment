import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/app/app.dart';
import 'package:little_bloom/core/auth/auth_controller.dart';
import 'package:little_bloom/core/storage/app_database.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens an empty in-memory database. SQLite runs on real threads, so this
/// must happen outside the widget test's fake clock ([WidgetTester.runAsync]).
Future<AppRepositories> openTestRepos(WidgetTester tester, {DateTime Function()? clock}) async {
  sqfliteFfiInit();
  final store = (await tester.runAsync(() => AppDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      )))!;
  addTearDown(() => tester.runAsync(store.close));
  return AppRepositories(store, clock: clock);
}

/// The whole app with test stores, like main.dart builds it.
Widget testApp(AuthController auth, AppRepositories repos) => Provider<AppRepositories>.value(
      value: repos,
      child: LittleBloomApp(auth: auth),
    );

/// Lets database work finish (real time), then redraws.
Future<void> settleDb(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  }
  await tester.pump(const Duration(seconds: 1)); // finish page transitions
}
