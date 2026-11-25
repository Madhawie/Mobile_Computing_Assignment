import 'package:flutter/services.dart';
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

/// M7 · Record vaccination: vaccine of the national schedule, dose, date
/// given (between birth and today) and an optional batch number.
class RecordVaccineScreen extends StatefulWidget {
  const RecordVaccineScreen({super.key, required this.childId, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final String childId;
  final DateTime Function() _clock;

  @override
  State<RecordVaccineScreen> createState() => _RecordVaccineScreenState();
}

class _RecordVaccineScreenState extends State<RecordVaccineScreen> {
  final _form = GlobalKey<FormState>();
  final _dose = TextEditingController(text: '1');
  final _batch = TextEditingController();
  Child? _child;
  String? _vaccine;
  late DateTime _date = dateOnly(widget._clock());
  String? _dateError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    context.read<AppRepositories>().children.getById(widget.childId).then((c) {
      if (mounted) setState(() => _child = c);
    });
  }

  @override
  void dispose() {
    _dose.dispose();
    _batch.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final c = _child;
    if (c == null) return;
    setState(() => _dateError = FormRules(t).notFuture(_date, widget._clock()) ??
        (_date.isBefore(dateOnly(c.dateOfBirth)) ? t.beforeBirth : null));
    if (!_form.currentState!.validate() || _dateError != null) return;

    setState(() => _busy = true);
    await PhmEntry(context.read<AppRepositories>()).recordVaccine(
      childId: c.id,
      vaccine: _vaccine!,
      dose: int.parse(_dose.text.trim()),
      givenOn: _date,
      batchNo: _batch.text,
    );
    if (mounted) savedAndClose(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final rules = FormRules(t);
    final today = widget._clock();

    return FormPage(
      title: t.recordVaccine,
      subtitle: _child?.name,
      formKey: _form,
      fields: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.vaccineLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              initialValue: _vaccine,
              items: [for (final v in vaccines) DropdownMenuItem(value: v, child: Text(v))],
              onChanged: (v) => setState(() => _vaccine = v),
              validator: (v) => v == null ? t.requiredField : null,
            ),
          ],
        ),
        LabeledField(
          label: t.doseLabel,
          controller: _dose,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => rules.wholeNumber(v, 1, 5),
        ),
        DateField(
          label: t.givenOnLabel,
          value: _date,
          errorText: _dateError,
          firstDate: _child?.dateOfBirth ?? DateTime(today.year - 5),
          lastDate: today,
          onChanged: (d) => setState(() {
            _date = d;
            _dateError = null;
          }),
        ),
        LabeledField(label: t.batchOptional, controller: _batch),
      ],
      buttons: [PrimaryButton(label: t.save, loading: _busy, onPressed: _child == null ? null : _save)],
    );
  }
}
