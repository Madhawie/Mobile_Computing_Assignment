import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import 'pin_input.dart';

/// C6 · Staff, first time on this phone: choose a PIN, then type it again.
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String? _first;
  String? _error;
  int _attempt = 0; // new key each round, so the box starts empty

  Future<void> _entered(String pin) async {
    if (_first == null) {
      setState(() {
        _first = pin;
        _error = null;
        _attempt++;
      });
      return;
    }
    if (pin != _first) {
      setState(() {
        _first = null;
        _error = AppLocalizations.of(context).pinsDoNotMatch;
        _attempt++;
      });
      return;
    }
    await context.read<AuthController>().setPin(pin); // router opens home
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final confirming = _first != null;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            const Icon(Icons.lock_outline_rounded, size: 48),
            const SizedBox(height: 16),
            Text(confirming ? t.confirmPinTitle : t.setPinTitle,
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(t.setPinHelp,
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            PinInput(
              key: ValueKey(_attempt),
              length: 4,
              semanticLabel: confirming ? t.confirmPinTitle : t.setPinTitle,
              onCompleted: _entered,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              StatusBanner(kind: StatusKind.warn, message: _error!),
            ],
          ],
        ),
      ),
    );
  }
}
