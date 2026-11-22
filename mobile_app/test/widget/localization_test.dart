import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/constants/app_language.dart';
import 'package:little_bloom/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Shows one translated string so the test can read it.
Widget _app(AppLanguage lang, String Function(AppLocalizations t) pick) => MaterialApp(
      locale: lang.locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) => Text(pick(AppLocalizations.of(context)))),
    );

void main() {
  test('all three languages are supported', () {
    final codes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    expect(codes, {'en', 'si', 'ta'});
    expect(AppLanguage.values.map((l) => l.code).toSet(), codes);
  });

  test('unknown language code falls back to English', () {
    expect(AppLanguage.fromCode('fr'), AppLanguage.english);
    expect(AppLanguage.fromCode('si'), AppLanguage.sinhala);
  });

  for (final (lang, expected) in [
    (AppLanguage.english, 'Who are you?'),
    (AppLanguage.sinhala, 'ඔබ කවුද?'),
    (AppLanguage.tamil, 'நீங்கள் யார்?'),
  ]) {
    testWidgets('${lang.name}: shows the translated text', (tester) async {
      await tester.pumpWidget(_app(lang, (t) => t.whoAreYou));
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
    });
  }

  testWidgets('plural: pending changes count', (tester) async {
    await tester.pumpWidget(_app(AppLanguage.english, (t) => t.pendingChanges(3)));
    await tester.pumpAndSettle();
    expect(find.text('3 changes waiting to send'), findsOneWidget);

    await tester.pumpWidget(_app(AppLanguage.english, (t) => t.pendingChanges(0)));
    await tester.pumpAndSettle();
    expect(find.text('Everything is sent'), findsOneWidget);
  });
}
