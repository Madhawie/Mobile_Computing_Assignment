import 'package:material_ui/material_ui.dart';

import '../core/constants/app_constants.dart';

/// Root widget of Little Bloom.
///
/// Later: Provider set-up (Day 6+), go_router (Day 8) and the theme (Day 4).
class LittleBloomApp extends StatelessWidget {
  const LittleBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: Text(AppConstants.appName)),
      ),
    );
  }
}
