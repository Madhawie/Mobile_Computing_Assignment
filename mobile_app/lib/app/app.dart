import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_controller.dart';
import '../core/constants/app_language.dart';
import '../core/theme/app_theme.dart';
import '../l10n/l10n.dart';
import 'router.dart';

/// Root widget of Little Bloom.
///
/// Rebuilds when [AuthController] changes: the chosen language sets the
/// locale and the signed-in role sets the colour (mother lavender, PHM mint,
/// MOH butter). The router moves between screens by itself.
class LittleBloomApp extends StatefulWidget {
  const LittleBloomApp({super.key, required this.auth});

  final AuthController auth;

  @override
  State<LittleBloomApp> createState() => _LittleBloomAppState();
}

class _LittleBloomAppState extends State<LittleBloomApp> {
  late final GoRouter _router = createRouter(widget.auth);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.auth,
      child: Consumer<AuthController>(
        builder: (context, auth, _) => MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.forRole(auth.role),
          locale: (auth.language ?? AppLanguage.english).locale,
          // Our strings (lib/l10n/*.arb) plus Flutter's own (date picker,
          // back button …), which already exist for Sinhala and Tamil.
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
        ),
      ),
    );
  }
}
