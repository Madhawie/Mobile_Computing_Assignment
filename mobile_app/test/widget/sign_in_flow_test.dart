import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/app/app.dart';
import 'package:little_bloom/core/auth/secure_store.dart';
import 'package:little_bloom/core/storage/meta_store.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_auth_api.dart';

/// Whole sign-in flows, tapping through the real screens and router.
void main() {
  Future<void> typeInto(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pumpAndSettle();
  }

  testWidgets('mother: language → role → phone → code → home', (tester) async {
    final auth = makeAuth();
    await auth.load();
    await tester.pumpWidget(LittleBloomApp(auth: auth));
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
    await typeInto(tester, fakeCode);

    expect(find.text('Hello, Test Mother'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('PHM: SMS → set PIN twice → home; reopen → unlock with PIN', (tester) async {
    final meta = MemoryMetaStore();
    final secure = MemorySecureStore();
    final auth = makeAuth(meta: meta, secure: secure);
    await auth.load();
    await tester.pumpWidget(LittleBloomApp(auth: auth));
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
    await typeInto(tester, '1357');
    expect(find.text('Hello, Test PHM'), findsOneWidget);

    // Close and open the app (new controller, same phone storage).
    final reopened = makeAuth(meta: meta, secure: secure);
    await reopened.load();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(LittleBloomApp(auth: reopened));
    await tester.pumpAndSettle();

    expect(find.text('Enter your PIN'), findsOneWidget);
    await typeInto(tester, '0000');
    expect(find.text('Wrong PIN. 4 tries left.'), findsOneWidget);
    await typeInto(tester, '1357');
    expect(find.text('Hello, Test PHM'), findsOneWidget);
  });

  testWidgets('unknown number shows "ask your midwife"', (tester) async {
    final auth = makeAuth();
    await auth.load();
    await tester.pumpWidget(LittleBloomApp(auth: auth));
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
    await tester.pumpWidget(LittleBloomApp(auth: auth));
    await tester.pumpAndSettle();
    await tester.tap(find.text('සිංහල'));
    await tester.pumpAndSettle();
    expect(find.text('ඔබ කවුද?'), findsOneWidget);
  });
}
