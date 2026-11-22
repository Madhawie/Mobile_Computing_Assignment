import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

class NavItem {
  const NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// Floating white bottom bar with 3–4 tabs (e.g. MOH: Overview · Mothers ·
/// Reports · Staff). The selected tab uses the role colour.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x1F504690), blurRadius: 24, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            for (final (i, item) in items.indexed)
              Expanded(
                child: Semantics(
                  selected: i == currentIndex,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon,
                            size: 24, color: i == currentIndex ? primary : AppColors.muted),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == currentIndex ? FontWeight.w800 : FontWeight.w700,
                            color: i == currentIndex ? primary : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
