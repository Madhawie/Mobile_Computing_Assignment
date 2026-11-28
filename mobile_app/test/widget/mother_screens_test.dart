import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/auth/auth_controller.dart';
import 'package:little_bloom/core/constants/app_language.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:little_bloom/features/parent/advice/advice_content.dart';
import 'package:little_bloom/features/parent/growth/growth_chart.dart';
import 'package:little_bloom/features/parent/parent_widgets.dart';

import '../helpers/fake_auth_api.dart';
import '../helpers/mother_data.dart';
import '../helpers/test_app.dart';

/// Mother screens through the real app and router, signed in as the test
/// mother (token motherId `m-1`). Synthetic family, dates relative to today.
void main() {
  late List<MethodCall> dialled;

  setUp(() {
    AdviceContent.clearCache();
    rootBundle.clear();
    dialled = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('little_bloom/phone'),
      (call) async {
        dialled.add(call);
        return true;
      },
    );
  });

  Future<void> signedInMother(WidgetTester tester, {bool withFamily = true}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final auth = makeAuth();
    await auth.setLanguage(AppLanguage.english);
    auth.choosePath(SignInPath.mother);
    await auth.requestCode('+94771234567');
    await auth.verifyCode(fakeCode);
    final AppRepositories repos = await openTestRepos(tester);
    if (withFamily) await tester.runAsync(() => addTestFamily(repos, DateTime.now()));
    await tester.pumpWidget(testApp(auth, repos));
    await settleDb(tester);
  }

  testWidgets('home: pregnancy, children, coming up, tip, and 1990 opens the dialler', (tester) async {
    await signedInMother(tester);
    expect(find.text('Hello, Test Mother'), findsOneWidget);
    expect(find.textContaining('28 weeks pregnant'), findsOneWidget);
    expect(find.text('Test Boy'), findsWidgets); // tile and "coming up"
    expect(find.text('Test Girl'), findsWidgets);
    expect(find.text('Late'), findsOneWidget); // the boy's 18-month vaccines
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('Tip for Test Girl'), findsOneWidget);
    expect(find.text('Start soft family foods'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Call 1990 · Suwa Seriya ambulance'), 300);
    await tester.tap(find.text('Call 1990 · Suwa Seriya ambulance'));
    await tester.pump();
    expect(dialled.single.arguments, {'number': '1990'});
  });

  testWidgets('child record → growth chart → vaccine card → advice', (tester) async {
    await signedInMother(tester);
    await tester.tap(find.text('Test Girl').first); // the child tile
    await settleDb(tester);
    expect(find.text('Child record'), findsOneWidget);
    expect(find.text('CHDR number: TST-0001'), findsOneWidget);
    expect(find.textContaining('Latest 7.8 kg'), findsOneWidget);

    await tester.tap(find.text('Growth chart'));
    await settleDb(tester);
    expect(find.text('Weight for age'), findsOneWidget);
    expect(find.byType(GrowthChart), findsOneWidget);
    expect(find.text('Within the normal range.'), findsOneWidget);
    expect(find.text('Measurements'), findsOneWidget);

    await tester.tap(find.text('Vaccines'));
    await settleDb(tester);
    expect(find.text('4 of 9 visits complete'), findsOneWidget);
    expect(find.text('On track'), findsOneWidget);
    expect(find.textContaining('Next: MMR 1'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('National Immunization Schedule, Sri Lanka'), 300);

    await tester.tap(find.text('Advice'));
    await settleDb(tester);
    expect(find.text('Start soft family foods'), findsOneWidget);
    await tester.tap(find.text('2–5 y'));
    await tester.pump();
    expect(find.text('A mix of foods every day'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Get help straight away'), 300);
  });

  testWidgets('switching child on one tab keeps it on the others', (tester) async {
    await signedInMother(tester);
    await tester.tap(find.text('Vaccines'));
    await settleDb(tester);
    expect(find.text('Some vaccines are late. Please go to the clinic.'), findsOneWidget); // the boy first

    await tester.tap(find.byWidgetPredicate((w) => w is ChildAvatar && w.child.name == 'Test Girl'));
    await tester.pump();
    expect(find.text('On track'), findsOneWidget);

    await tester.tap(find.text('Growth'));
    await settleDb(tester);
    expect(find.textContaining('Test Girl · Girl'), findsOneWidget);
  });

  testWidgets('my pregnancy: weeks, next visit, danger signs, visits', (tester) async {
    await signedInMother(tester);
    await tester.tap(find.text('My pregnancy'));
    await settleDb(tester);
    expect(find.text('28 weeks pregnant'), findsOneWidget);
    expect(find.textContaining('Next visit'), findsOneWidget);
    await settleDb(tester); // the advice file loads
    await tester.scrollUntilVisible(find.text('Go to hospital straight away'), 300);
    expect(find.textContaining('BP 118/76'), findsOneWidget);
  });

  testWidgets('nothing synced yet: says when records will appear', (tester) async {
    await signedInMother(tester, withFamily: false);
    expect(find.textContaining('Your records appear here'), findsOneWidget);
    expect(find.text('Call 1990 · Suwa Seriya ambulance'), findsOneWidget);
  });
}
