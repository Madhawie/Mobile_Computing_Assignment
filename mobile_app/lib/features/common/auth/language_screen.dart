import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/constants/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';

/// C1 · Choose language. First screen on a new phone.
/// Each language is written in its own script so anyone can find theirs.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final current = context.watch<AuthController>().language;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.local_florist_rounded, size: 56, color: AppColors.motherDark),
              const SizedBox(height: 16),
              Text(t.welcome,
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(t.welcomeHint,
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 40),
              // Shown in all three, because the user may not read the current one.
              const Text('භාෂාව තෝරන්න · மொழியைத் தேர்ந்தெடுக்கவும் · Choose your language',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted)),
              const SizedBox(height: 16),
              for (final lang in AppLanguage.values) ...[
                _LanguageButton(
                  language: lang,
                  selected: lang == current,
                  onTap: () async {
                    await context.read<AuthController>().setLanguage(lang);
                    if (context.mounted) context.go(Routes.role);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.language, required this.selected, required this.onTap});

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.motherLight : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? AppColors.motherDark : AppColors.border, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Center(
            child: Text(language.nativeName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
