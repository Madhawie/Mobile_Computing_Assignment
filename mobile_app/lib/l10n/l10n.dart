import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Delegates for MaterialApp.
///
/// We do not use the generated `AppLocalizations.localizationsDelegates`:
/// since Flutter 3.47 Material widgets live in package:material_ui and need
/// its own GlobalMaterialLocalizations (which has Sinhala and Tamil). The
/// old ones from flutter_localizations are deprecated and not found by
/// MaterialApp, so si / ta would fail.
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];
