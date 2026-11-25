import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/phone_number.dart';
import '../../../data/repositories/app_repositories.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../forms/form_page.dart';
import '../forms/form_rules.dart';
import '../forms/phm_entry.dart';

/// S4 / M3 · Add mother. Her mobile number becomes her sign-in (no
/// self sign-up). Saved offline in the PHM's own area.
class AddMotherScreen extends StatefulWidget {
  const AddMotherScreen({super.key, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  State<AddMotherScreen> createState() => _AddMotherScreenState();
}

class _AddMotherScreenState extends State<AddMotherScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _age = TextEditingController();
  final _address = TextEditingController();
  final _weeks = TextEditingController();
  bool _pregnant = true;
  DateTime? _dueDate;
  bool _dueDateTouched = false;
  String? _phoneError;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _age, _address, _weeks]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fills the due date from the weeks, until the PHM picks one herself.
  void _weeksChanged(String v) {
    final w = int.tryParse(v);
    if (!_dueDateTouched && w != null && w >= 1 && w <= 42) {
      setState(() => _dueDate = FormRules.dueDateFromWeeks(w, widget._clock()));
    }
  }

  Future<void> _save({required bool thenAddChild}) async {
    setState(() => _phoneError = null);
    if (!_form.currentState!.validate()) return;
    final entry = PhmEntry(context.read<AppRepositories>());
    final t = AppLocalizations.of(context);
    final areaId = context.read<AuthController>().session?.user.areaId ?? '';
    final phone = PhoneNumber.normalise(_phone.text)!;

    setState(() => _busy = true);
    if (await entry.phoneTaken(phone)) {
      setState(() {
        _busy = false;
        _phoneError = t.phoneAlreadyRegistered;
      });
      return;
    }
    final mother = await entry.addMother(
      fullName: _name.text,
      phone: phone,
      age: int.parse(_age.text.trim()),
      address: _address.text,
      areaId: areaId,
      isPregnant: _pregnant,
      gestationWeeks: _pregnant ? int.parse(_weeks.text.trim()) : null,
      dueDate: _pregnant ? _dueDate : null,
    );
    if (!mounted) return;
    if (thenAddChild) {
      context.pushReplacement(Routes.phmAddChild(mother.id));
    } else {
      savedAndClose(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final rules = FormRules(t);
    final today = widget._clock();
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return FormPage(
      title: t.addMother,
      formKey: _form,
      fields: [
        LabeledField(label: t.fullName, controller: _name, validator: rules.required),
        LabeledField(
          label: t.yourMobileNumber,
          controller: _phone,
          prefixText: '+94 ',
          hint: '76 482 3310',
          keyboardType: TextInputType.phone,
          validator: (v) => PhoneNumber.normalise(v ?? '') == null ? t.invalidPhone : null,
        ),
        if (_phoneError != null) StatusBanner(kind: StatusKind.warn, message: _phoneError!),
        LabeledField(
          label: t.ageLabel,
          controller: _age,
          keyboardType: TextInputType.number,
          inputFormatters: digits,
          validator: (v) => rules.wholeNumber(v, 14, 55),
        ),
        LabeledField(label: t.addressLabel, controller: _address, validator: rules.required),
        Text(t.pregnantNow, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
        ChoiceToggle<bool>(
          options: [ChoiceOption(true, t.yes), ChoiceOption(false, t.no)],
          selected: _pregnant,
          onChanged: (v) => setState(() => _pregnant = v),
        ),
        if (_pregnant) ...[
          LabeledField(
            label: t.weeksPregnant,
            controller: _weeks,
            keyboardType: TextInputType.number,
            inputFormatters: digits,
            onChanged: _weeksChanged,
            validator: (v) => rules.wholeNumber(v, 1, 42),
          ),
          DateField(
            label: t.dueDateLabel,
            value: _dueDate,
            firstDate: today,
            lastDate: today.add(const Duration(days: 300)),
            onChanged: (d) => setState(() {
              _dueDate = d;
              _dueDateTouched = true;
            }),
          ),
        ],
      ],
      buttons: [
        PrimaryButton(label: t.saveMother, loading: _busy, onPressed: () => _save(thenAddChild: false)),
        SecondaryButton(label: t.saveAndAddChild, onPressed: _busy ? null : () => _save(thenAddChild: true)),
      ],
    );
  }
}
