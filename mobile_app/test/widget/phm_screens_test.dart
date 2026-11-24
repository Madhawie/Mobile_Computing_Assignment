import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/auth/auth_controller.dart';
import 'package:little_bloom/core/constants/app_language.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_auth_api.dart';
import '../helpers/test_app.dart';

/// PHM screens through the real app and router, signed in as the test PHM.
void main() {
  Future<void> signedInPhm(WidgetTester tester) async {
    final auth = makeAuth();
    await auth.setLanguage(AppLanguage.english);
    auth.choosePath(SignInPath.staff);
    await auth.requestCode('+94700000002');
    await auth.verifyCode(fakeCode);
    await auth.setPin('1357');
    await tester.pumpWidget(testApp(auth, await openTestRepos(tester)));
    await settleDb(tester);
  }

  testWidgets('empty area: Today says nothing due; register offers sample data', (tester) async {
    await signedInPhm(tester);
    expect(find.text('Hello, Test PHM'), findsOneWidget);
    expect(find.text('Nothing due this week.'), findsOneWidget);
    expect(find.text('Everything is sent'), findsOneWidget);

    await tester.tap(find.text('Register'));
    await settleDb(tester);
    expect(find.text('No mothers in your area yet.'), findsOneWidget);
    expect(find.text('Load sample data (testing only)'), findsOneWidget);
  });

  testWidgets('sample data → register → search → mother detail → back to Today', (tester) async {
    await signedInPhm(tester);
    await tester.tap(find.text('Register'));
    await settleDb(tester);
    await tester.tap(find.text('Load sample data (testing only)'));
    await settleDb(tester);

    expect(find.text('Dilani Silva'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsWidgets); // not sent yet

    await tester.enterText(find.byType(TextField), 'fath');
    await tester.pump();
    expect(find.text('Dilani Silva'), findsNothing);
    await tester.tap(find.text('Fathima Rizna'));
    await settleDb(tester);

    expect(find.text('Pregnant · 33 weeks'), findsOneWidget);
    expect(find.text('Pregnancy visits'), findsOneWidget);
    expect(find.textContaining('Blood pressure is high'), findsOneWidget);
    expect(find.text('3 days late'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await settleDb(tester);
    await tester.tap(find.text('Today'));
    await settleDb(tester);
    expect(find.textContaining('Pregnancy visits due'), findsOneWidget);
    expect(find.textContaining('Children to weigh'), findsOneWidget);
    expect(find.text('17 changes waiting to send'), findsOneWidget);
  });
}
