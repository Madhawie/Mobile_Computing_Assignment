import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/auth/auth_controller.dart';
import 'package:little_bloom/core/constants/app_language.dart';
import 'package:little_bloom/core/theme/app_theme.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:little_bloom/features/phm/forms/phm_entry.dart';
import 'package:little_bloom/features/phm/growth_record/record_growth_screen.dart';
import 'package:little_bloom/features/phm/home_visit/antenatal_visit_screen.dart';
import 'package:little_bloom/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_api.dart';
import '../helpers/test_app.dart';
import '../unit/phm_forms_test.dart' show fakeReference, weightAtZ;

/// One form on its own, with the test database.
Widget formApp(AppRepositories repos, Widget screen) => Provider<AppRepositories>.value(
      value: repos,
      child: MaterialApp(
        theme: AppTheme.forRole(null),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    );

Future<void> type(WidgetTester tester, String label, String text) async {
  // Fields below the fold are not built until scrolled to.
  await tester.scrollUntilVisible(find.text(label), 150, scrollable: find.byType(Scrollable).first);
  final field = find.ancestor(of: find.text(label), matching: find.byType(Column)).first;
  await tester.enterText(find.descendant(of: field, matching: find.byType(TextField)), text);
  await tester.pump();
}

void main() {
  testWidgets('add mother from the register; a used number is refused', (tester) async {
    final auth = makeAuth();
    await auth.setLanguage(AppLanguage.english);
    auth.choosePath(SignInPath.staff);
    await auth.requestCode('+94700000002');
    await auth.verifyCode(fakeCode);
    await auth.setPin('1357');
    await tester.pumpWidget(testApp(auth, await openTestRepos(tester)));
    await settleDb(tester);
    await tester.tap(find.text('Register'));
    await settleDb(tester);

    Future<void> fillAndSave() async {
      await tester.tap(find.text('Add mother'));
      await settleDb(tester);
      await type(tester, 'Full name', 'Test New Mother');
      await type(tester, 'Your mobile number', '070 000 0160');
      await type(tester, 'Age', '24');
      await type(tester, 'Address', 'Test Road');
      await type(tester, 'Weeks pregnant', '18');
      await tester.tap(find.text('Save mother'));
      await settleDb(tester);
    }

    await fillAndSave();
    expect(find.text('Test New Mother'), findsOneWidget); // back on the register
    expect(find.textContaining('Pregnant · 18 weeks'), findsOneWidget);

    await fillAndSave(); // same number again
    expect(find.text('This mobile number is already registered.'), findsOneWidget);
  });

  group('record growth', () {
    Future<(AppRepositories, String)> withChild(WidgetTester tester) async {
      final repos = await openTestRepos(tester);
      final child = (await tester.runAsync(() async {
        final e = PhmEntry(repos);
        final m = await e.addMother(fullName: 'M', phone: '+94700000170', age: 25, address: 'x',
            areaId: 'glg-east', isPregnant: false);
        return e.addChild(motherId: m.id, name: 'Test Baby', sex: Sex.boy,
            dateOfBirth: DateTime(2026, 5, 1), birthWeightKg: 3.0);
      }))!;
      return (repos, child.id);
    }

    for (final (z, text) in [
      (0.0, 'Green zone · normal weight for age'),
      (-2.5, 'Orange zone'),
      (-3.5, 'Red zone · severely underweight. Refer to the MOH clinic.'),
    ]) {
      testWidgets('weight at z = $z shows "$text"', (tester) async {
        final (repos, childId) = await withChild(tester);
        await tester.pumpWidget(formApp(repos, RecordGrowthScreen(
          childId: childId,
          reference: fakeReference(), // made-up table, not WHO
          clock: () => DateTime(2026, 11, 25),
        )));
        await settleDb(tester);
        await type(tester, 'Weight (kg)', weightAtZ(z).toStringAsFixed(3));
        expect(find.textContaining(text), findsOneWidget);
      });
    }

    testWidgets('without the WHO table: saves, and says the zone is not available', (tester) async {
      final (repos, childId) = await withChild(tester);
      await tester.pumpWidget(formApp(repos, RecordGrowthScreen(childId: childId)));
      await settleDb(tester);
      await type(tester, 'Weight (kg)', '7.2');
      expect(find.textContaining('Growth zone not shown'), findsOneWidget);
    });
  });

  testWidgets('pregnancy visit: weeks filled in, BP warning and order check', (tester) async {
    final repos = await openTestRepos(tester);
    final mother = (await tester.runAsync(() => PhmEntry(repos).addMother(
          fullName: 'Test Mother', phone: '+94700000180', age: 25, address: 'x', areaId: 'glg-east',
          isPregnant: true, gestationWeeks: 30)))!;
    await tester.pumpWidget(formApp(repos, AntenatalVisitScreen(motherId: mother.id)));
    await settleDb(tester);

    expect(find.text('30'), findsOneWidget); // weeks from her record

    await type(tester, 'BP top number', '150');
    expect(find.text('Blood pressure is high'), findsOneWidget);

    await type(tester, 'BP top number', '80');
    await type(tester, 'BP bottom number', '120');
    await type(tester, "Mother's weight (kg)", '64');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('The top number must be higher than the bottom number.'), findsOneWidget);
  });
}
