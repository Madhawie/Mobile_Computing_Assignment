import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/app_repositories.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../forms/form_page.dart';
import '../forms/form_rules.dart';
import '../forms/phm_entry.dart';
import '../phm_rules.dart';

/// M3 · Register a newborn (or any child under 5) for a mother.
/// Boy / girl decides the blue or pink CHDR chart; under 2.5 kg puts the
/// baby on the PHM's watch list.
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key, required this.motherId, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final String motherId;
  final DateTime Function() _clock;

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _birthWeight = TextEditingController();
  Mother? _mother;
  Sex? _sex;
  late DateTime _dob = dateOnly(widget._clock());
  String? _sexError;
  String? _dobError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    context.read<AppRepositories>().mothers.getById(widget.motherId).then((m) {
      if (mounted) setState(() => _mother = m);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _birthWeight.dispose();
    super.dispose();
  }

  double? get _weight => FormRules.parseNumber(_birthWeight.text);

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final today = widget._clock();
    setState(() {
      _sexError = _sex == null ? t.requiredField : null;
      _dobError = FormRules(t).notFuture(_dob, today) ??
          (ageInMonths(_dob, today) >= childFollowUpMonths ? t.olderThanFive : null);
    });
    if (!_form.currentState!.validate() || _sexError != null || _dobError != null) return;

    setState(() => _busy = true);
    await PhmEntry(context.read<AppRepositories>()).addChild(
      motherId: widget.motherId,
      name: _name.text,
      sex: _sex!,
      dateOfBirth: _dob,
      birthWeightKg: _weight!,
    );
    if (mounted) savedAndClose(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final rules = FormRules(t);
    final today = widget._clock();
    final w = _weight;

    return FormPage(
      title: t.addChild,
      subtitle: _mother?.fullName,
      formKey: _form,
      fields: [
        LabeledField(label: t.childName, controller: _name, validator: rules.required),
        Text(t.boyOrGirl, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
        ChoiceToggle<Sex>(
          options: [
            for (final o in ChoiceToggle.sexOptions(boy: t.boy, girl: t.girl))
              ChoiceOption(Sex.values.byName(o.value), o.label,
                  background: o.background, foreground: o.foreground, border: o.border),
          ],
          selected: _sex,
          onChanged: (v) => setState(() {
            _sex = v;
            _sexError = null;
          }),
        ),
        Text(_sexError ?? t.sexChartHint,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _sexError == null ? null : Theme.of(context).colorScheme.error)),
        DateField(
          label: t.dateOfBirth,
          value: _dob,
          errorText: _dobError,
          firstDate: DateTime(today.year - 5, today.month, today.day),
          lastDate: today,
          onChanged: (d) => setState(() {
            _dob = d;
            _dobError = null;
          }),
        ),
        LabeledField(
          label: t.birthWeightKg,
          controller: _birthWeight,
          keyboardType: LabeledField.decimal,
          onChanged: (_) => setState(() {}),
          validator: (v) => rules.number(v, 0.5, 6),
        ),
        if (w != null && w >= 0.5 && w < 2.5) StatusBanner(kind: StatusKind.warn, message: t.lowBirthWeightWatch),
      ],
      buttons: [PrimaryButton(label: t.saveChild, loading: _busy, onPressed: _save)],
    );
  }
}
