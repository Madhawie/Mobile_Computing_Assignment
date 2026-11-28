import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/widgets.dart';

/// Frame around the mother's screens with the bottom menu
/// (design: Home · Growth · Vaccines; Advice instead of the Visits calendar).
class MotherShell extends StatelessWidget {
  const MotherShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const tabs = [Routes.motherHome, Routes.motherGrowth, Routes.motherVaccines, Routes.motherAdvice];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final index = tabs.lastIndexWhere((p) => location == p || (p != Routes.motherHome && location.startsWith(p)));
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        currentIndex: index < 0 ? 0 : index,
        onTap: (i) => context.go(tabs[i]),
        items: [
          NavItem(Icons.home_rounded, t.tabHome),
          NavItem(Icons.show_chart_rounded, t.tabGrowth),
          NavItem(Icons.vaccines_rounded, t.tabVaccines),
          NavItem(Icons.lightbulb_outline_rounded, t.tabAdvice),
        ],
      ),
    );
  }
}
