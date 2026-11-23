import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/widgets.dart';

/// Temporary home for every role until the real screens are built.
/// Shows who is signed in (name, role, area) and a sign-out button.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.session?.user;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.helloName(user?.name ?? ''), style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text([user?.role, user?.areaId ?? user?.mohId].whereType<String>().join(' · '),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t.comingSoon, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
              const Spacer(),
              SecondaryButton(label: t.signOut, onPressed: auth.signOut),
            ],
          ),
        ),
      ),
    );
  }
}
