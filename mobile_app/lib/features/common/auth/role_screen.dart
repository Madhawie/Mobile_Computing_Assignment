import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';

/// C2 · Who are you? Decides the sign-in path:
/// mother → phone + SMS code; PHM / MOH office → SMS code first time, then PIN.
/// Nobody signs up here: accounts are made by the PHM or the MOH office.
class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    void pick(SignInPath path) {
      context.read<AuthController>().choosePath(path);
      context.go(Routes.phone);
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Text(t.whoAreYou, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            _RoleCard(
              icon: Icons.child_care_rounded,
              title: t.roleMother,
              hint: t.roleMotherHint,
              light: AppColors.motherLight,
              dark: AppColors.motherDark,
              onTap: () => pick(SignInPath.mother),
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.medical_services_rounded,
              title: t.rolePhm,
              hint: t.rolePhmHint,
              light: AppColors.phmLight,
              dark: AppColors.phmDark,
              onTap: () => pick(SignInPath.staff),
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.apartment_rounded,
              title: t.roleAdmin,
              hint: t.roleAdminHint,
              light: AppColors.mohLight,
              dark: AppColors.mohDark,
              onTap: () => pick(SignInPath.staff),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => context.go(Routes.language),
              icon: const Icon(Icons.translate_rounded),
              label: Text(t.changeLanguage),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.light,
    required this.dark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final Color light;
  final Color dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, color: dark, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(hint, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: dark),
            ],
          ),
        ),
      ),
    );
  }
}
