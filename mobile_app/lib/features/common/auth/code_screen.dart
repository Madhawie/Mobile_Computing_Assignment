import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/phone_number.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import 'pin_input.dart';
import 'sign_in_errors.dart';

/// C3 · SMS code. On success the router moves on by itself:
/// mother → home, staff → set PIN.
class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key});

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final _input = GlobalKey<PinInputState>();
  bool _busy = false;
  String? _error;

  Future<void> _check(String code) async {
    final auth = context.read<AuthController>();
    final t = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.verifyCode(code); // router redirects on success
    } catch (e) {
      _input.currentState?.clear();
      if (mounted) setState(() => _error = signInMessage(e, t, auth.path));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthController>();
    final t = AppLocalizations.of(context);
    try {
      await auth.requestCode(auth.otpPhone!);
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = signInMessage(e, t, auth.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final phone = context.watch<AuthController>().otpPhone ?? '';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ScreenHeader(title: t.enterCode, onBack: () => context.go(Routes.phone)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.codeSentTo(PhoneNumber.pretty(phone)),
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  PinInput(
                    key: _input,
                    length: 6,
                    obscure: false,
                    enabled: !_busy,
                    semanticLabel: t.enterCode,
                    onCompleted: _check,
                  ),
                  if (_busy) const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    StatusBanner(kind: StatusKind.warn, message: _error!),
                  ],
                  const SizedBox(height: 16),
                  TextButton(onPressed: _busy ? null : _resend, child: Text(t.resendCode)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
