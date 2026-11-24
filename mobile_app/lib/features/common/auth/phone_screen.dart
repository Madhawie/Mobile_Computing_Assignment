import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/phone_number.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import 'sign_in_errors.dart';

/// C3 · Mobile number. The server sends an SMS code if the number belongs to
/// a registered mother or staff member (no self sign-up).
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phone = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final t = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.requestCode(PhoneNumber.normalise(_phone.text)!);
      if (mounted) context.go(Routes.code);
    } catch (e) {
      if (mounted) setState(() => _error = signInMessage(e, t, auth.path));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ScreenHeader(title: t.yourMobileNumber, onBack: () => context.go(Routes.role)),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabeledField(
                      label: t.yourMobileNumber,
                      controller: _phone,
                      hint: '76 482 3310',
                      prefixText: '+94 ',
                      keyboardType: TextInputType.phone,
                      validator: (v) => PhoneNumber.normalise(v ?? '') == null ? t.invalidPhone : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      StatusBanner(kind: StatusKind.warn, message: _error!),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(label: t.sendCode, loading: _busy, onPressed: _send),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
