import 'package:material_ui/material_ui.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

/// Root widget of Little Bloom.
///
/// Later: Provider set-up (Day 6+) and go_router (Day 8).
class LittleBloomApp extends StatelessWidget {
  const LittleBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      // Neutral colour until sign-in; the role colour is set on Day 8.
      theme: AppTheme.forRole(null),
      home: const Scaffold(
        body: Center(child: Text(AppConstants.appName)),
      ),
    );
  }
}
