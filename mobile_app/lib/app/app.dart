import 'package:material_ui/material_ui.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_language.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';

/// Root widget of Little Bloom.
///
/// Later: Provider set-up (Day 6+) and go_router (Day 8). On Day 8 the
/// language screen sets [language] and the signed-in role sets the theme.
class LittleBloomApp extends StatelessWidget {
  const LittleBloomApp({super.key, this.language = AppLanguage.english});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      // Neutral colour until sign-in.
      theme: AppTheme.forRole(null),
      locale: language.locale,
      // Our strings (lib/l10n/*.arb) plus Flutter's own (date picker, back
      // button …), which already exist for Sinhala and Tamil.
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: Center(child: Text(AppConstants.appName)),
      ),
    );
  }
}
