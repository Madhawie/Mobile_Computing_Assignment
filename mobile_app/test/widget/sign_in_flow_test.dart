import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/auth/secure_store.dart';
import 'package:little_bloom/core/storage/meta_store.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_auth_api.dart';
import '../helpers/test_app.dart';

/// Whole sign-in flows, tapping through the real screens and router.
void main() {
  Future<void> typeInto(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pumpAndSettle();
  }

  /// Last step before a home that reads the database: no pumpAndSettle,
  /// because the loading spinner never settles under the fake clock.
  Future<void> typeIntoThenLoad(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pump();
    await settleDb(tester);
  }

  testWidgets('mother: language → role → phone → code → home', (tester) async {
    final auth = makeAuth();
    await auth.load();
    await tester.pumpWidget(testApp(auth, await openTestRepos(tester)));
    await tester.pumpAndSettle();

    expect(find.text('සිංහල'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Who are you?'), findsOneWidget);
    await tester.tap(find.text('I am a mother'));
    await tester.pumpAndSettle();

    await typeInto(tester, '077 123 4567');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.textContaining('+94 77 123 4567'), findsOneWidget);
    await typeIntoThenLoad(tester, fakeCode);

    expect(find.text('Hello, Test Mother'), findsOneWidget);
    expect(find.byTooltip('Sign out'), findsOneWidget); // mother home (Day 16)
  });

  testWidgets('PHM: SMS → set PIN twice → home; reopen → unlock with PIN', (tester) async {
    final meta = MemoryMetaStore();
    final secure = MemorySecureStore();
    final auth = makeAuth(meta: meta, secure: secure);
    await auth.load();
    await tester.pumpWidget(testApp(auth, await openTestRepos(tester)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I am a midwife (PHM)'));
    await tester.pumpAndSettle();
    await typeInto(tester, '0700000002');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    await typeInto(tester, fakeCode);

    expect(find.text('Choose a 4-digit PIN'), findsOneWidget);
    await typeInto(tester, '1357');
    expect(find.text('Type the PIN again'), findsOneWidget);
    await typeIntoThenLoad(tester, '1357');
    expect(find.text('Hello, Test PHM'), findsOneWidget);

    // Close and open the app (new controller, same phone storage).
    final reopened = makeAuth(meta: meta, secure: secure);
    await reopened.load();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(testApp(reopened, await openTestRepos(tester)));
    await tester.pumpAndSettle();

    expect(find.text('Enter your PIN'), findsOneWidget);
    await typeInto(tester, '0000');
    expect(find.text('Wrong PIN. 4 tries left.'), findsOneWidget);
    await typeIntoThenLoad(tester, '1357');
    expect(find.text('Hello, Test PHM'), findsOneWidget);
  });

  testWidgets('unknown number shows "ask your midwife"', (tester) async {
    final auth = makeAuth();
    await auth.load();
    await tester.pumpWidget(testApp(auth, await openTestRepos(tester)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I am a mother'));
    await tester.pumpAndSettle();
    await typeInto(tester, '0711111111');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ask your midwife'), findsOneWidget);
  });

  testWidgets('Sinhala is used on the next screen after choosing it', (tester) async {
    final auth = makeAuth();
    await auth.load();
    await tester.pumpWidget(testApp(auth, await openTestRepos(tester)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('සිංහල'));
    await tester.pumpAndSettle();
    expect(find.text('ඔබ කවුද?'), findsOneWidget);
  });
}
