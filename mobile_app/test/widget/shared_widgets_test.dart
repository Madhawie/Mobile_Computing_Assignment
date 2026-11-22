import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/constants/user_role.dart';
import 'package:little_bloom/core/theme/app_colors.dart';
import 'package:little_bloom/core/theme/app_theme.dart';
import 'package:little_bloom/shared/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap(Widget child, {UserRole? role}) => MaterialApp(
      theme: AppTheme.forRole(role),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  test('each role gets its own main colour', () {
    expect(AppTheme.forRole(UserRole.phm).colorScheme.primary, AppColors.phmDark);
    expect(AppTheme.forRole(UserRole.mother).colorScheme.primary, AppColors.motherDark);
    expect(AppTheme.forRole(UserRole.admin).colorScheme.primary, AppColors.mohDark);
    expect(AppTheme.forRole(UserRole.supervisor).colorScheme.primary, AppColors.mohDark);
  });

  testWidgets('PrimaryButton calls onPressed and is disabled while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(PrimaryButton(label: 'Save', onPressed: () => taps++)));
    await tester.tap(find.text('Save'));
    expect(taps, 1);

    await tester.pumpWidget(_wrap(PrimaryButton(label: 'Save', onPressed: () => taps++, loading: true)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 1);
  });

  testWidgets('ChoiceToggle reports the tapped value', (tester) async {
    String? picked;
    await tester.pumpWidget(_wrap(ChoiceToggle<String>(
      options: ChoiceToggle.sexOptions(boy: 'Boy', girl: 'Girl'),
      selected: 'boy',
      onChanged: (v) => picked = v,
    )));
    await tester.tap(find.text('Girl'));
    expect(picked, 'girl');
  });

  testWidgets('StatusBanner shows text and an icon, not only colour', (tester) async {
    await tester.pumpWidget(_wrap(const StatusBanner(kind: StatusKind.warn, message: 'Low birth weight')));
    expect(find.text('Low birth weight'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('RecordTile shows the first letter and details', (tester) async {
    await tester.pumpWidget(_wrap(RecordTile(title: 'test mother', subtitle: 'Area 1', onTap: () {})));
    expect(find.text('T'), findsOneWidget);
    expect(find.text('Area 1'), findsOneWidget);
  });

  testWidgets('AppBottomNav reports the tapped tab', (tester) async {
    var index = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: AppBottomNav(
          items: const [NavItem(Icons.home, 'Home'), NavItem(Icons.sync, 'Sync')],
          currentIndex: 0,
          onTap: (i) => index = i,
        ),
      ),
    ));
    await tester.tap(find.text('Sync'));
    expect(index, 1);
  });

  testWidgets('LabeledField shows its label and accepts text', (tester) async {
    final c = TextEditingController();
    await tester.pumpWidget(_wrap(LabeledField(label: 'Weight (kg)', controller: c)));
    await tester.enterText(find.byType(TextFormField), '7.4');
    expect(find.text('Weight (kg)'), findsOneWidget);
    expect(c.text, '7.4');
  });
}
