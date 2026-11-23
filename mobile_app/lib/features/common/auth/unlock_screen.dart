import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import 'pin_input.dart';

/// C4 / C5 · Staff open the app with their PIN. Checked on the phone, so it
/// works in a village with no signal.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _input = GlobalKey<PinInputState>();
  String? _error;
  bool _busy = false;

  Future<void> _entered(String pin) async {
    final t = AppLocalizations.of(context);
    setState(() => _busy = true);
    final result = await context.read<AuthController>().unlock(pin);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case PinOk():
        break; // router opens home
      case PinWrong(:final triesLeft):
        _input.currentState?.clear();
        setState(() => _error = t.wrongPin(triesLeft));
      case PinLockedOut():
        // AuthController signed out; the router goes back to "Who are you?".
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.pinLockedOut)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            if (auth.session != null)
              Text(t.helloName(auth.session!.user.name),
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(t.enterPin, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            PinInput(key: _input, length: 4, enabled: !_busy, semanticLabel: t.enterPin, onCompleted: _entered),
            if (_error != null) ...[
              const SizedBox(height: 14),
              StatusBanner(kind: StatusKind.danger, message: _error!),
            ],
            const SizedBox(height: 24),
            TextButton(onPressed: () => auth.signOut(), child: Text(t.forgotPin)),
          ],
        ),
      ),
    );
  }
}
