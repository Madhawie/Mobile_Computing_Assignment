import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/widgets.dart';

/// Frame around the PHM's main tabs: the screen on top, the bottom menu below.
/// Sync joins the menu on Day 14.
class PhmShell extends StatelessWidget {
  const PhmShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = [Routes.phmHome, Routes.phmRegister];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final index = location.startsWith(Routes.phmRegister) ? 1 : 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        currentIndex: index,
        onTap: (i) => context.go(_tabs[i]),
        items: [
          NavItem(Icons.today_rounded, t.today),
          NavItem(Icons.groups_rounded, t.register),
        ],
      ),
    );
  }
}
