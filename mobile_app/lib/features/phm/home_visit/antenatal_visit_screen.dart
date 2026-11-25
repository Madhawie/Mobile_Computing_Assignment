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

/// P6 · Record pregnancy visit: weeks, weight, blood pressure (red warning at
/// 140/90 or more), and the next visit date suggested from the weeks.
class AntenatalVisitScreen extends StatefulWidget {
  const AntenatalVisitScreen({super.key, required this.motherId, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final String motherId;
  final DateTime Function() _clock;

  @override
  State<AntenatalVisitScreen> createState() => _AntenatalVisitScreenState();
}

class _AntenatalVisitScreenState extends State<AntenatalVisitScreen> {
  final _form = GlobalKey<FormState>();
  final _weeks = TextEditingController();
  final _weight = TextEditingController();
  final _top = TextEditingController();
  final _bottom = TextEditingController();
  final _notes = TextEditingController();
  Mother? _mother;
  late DateTime _date = dateOnly(widget._clock());
  DateTime? _next;
  bool _nextTouched = false;
  String? _dateError, _nextError, _bpError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    context.read<AppRepositories>().mothers.getById(widget.motherId).then((m) {
      if (!mounted || m == null) return;
      setState(() => _mother = m);
      if (m.gestationWeeks != null) {
        _weeks.text = '${m.gestationWeeks}';
        _suggestNext();
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_weeks, _weight, _top, _bottom, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _suggestNext() {
    final w = int.tryParse(_weeks.text.trim());
    if (_nextTouched || w == null || w < 1 || w > 42) return;
    setState(() => _next = FormRules.suggestedNextVisit(w, _date));
  }

  bool get _highBp {
    final a = FormRules.parseNumber(_top.text), b = FormRules.parseNumber(_bottom.text);
    return (a != null && a >= 140) || (b != null && b >= 90);
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final rules = FormRules(t);
    final m = _mother;
    if (m == null) return;
    setState(() {
      _dateError = rules.notFuture(_date, widget._clock());
      _nextError = _next != null && !_next!.isAfter(_date) ? t.nextVisitAfter : null;
      _bpError = rules.bloodPressure(_top.text, _bottom.text);
    });
    if (!_form.currentState!.validate() || _dateError != null || _nextError != null || _bpError != null) return;

    setState(() => _busy = true);
    await PhmEntry(context.read<AppRepositories>()).recordVisit(
      mother: m,
      visitDate: _date,
      gestationWeeks: int.parse(_weeks.text.trim()),
      weightKg: FormRules.parseNumber(_weight.text)!,
      bpSystolic: FormRules.parseNumber(_top.text)!.round(),
      bpDiastolic: FormRules.parseNumber(_bottom.text)!.round(),
      nextVisit: _next,
      notes: _notes.text,
    );
    if (mounted) savedAndClose(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final rules = FormRules(t);
    final today = widget._clock();
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return FormPage(
      title: t.recordVisit,
      subtitle: _mother?.fullName,
      formKey: _form,
      fields: [
        DateField(
          label: t.dateLabel,
          value: _date,
          errorText: _dateError,
          firstDate: today.subtract(const Duration(days: 300)),
          lastDate: today,
          onChanged: (d) {
            setState(() {
              _date = d;
              _dateError = null;
            });
            _suggestNext();
          },
        ),
        LabeledField(
          label: t.weeksPregnant,
          controller: _weeks,
          keyboardType: TextInputType.number,
          inputFormatters: digits,
          onChanged: (_) => _suggestNext(),
          validator: (v) => rules.wholeNumber(v, 1, 42),
        ),
        LabeledField(
          label: t.motherWeightKg,
          controller: _weight,
          keyboardType: LabeledField.decimal,
          validator: (v) => rules.number(v, 30, 150),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledField(
                label: t.bpTop,
                controller: _top,
                hint: '120',
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                onChanged: (_) => setState(() => _bpError = null),
                validator: (v) => rules.wholeNumber(v, 70, 250),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledField(
                label: t.bpBottom,
                controller: _bottom,
                hint: '80',
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                onChanged: (_) => setState(() => _bpError = null),
                validator: (v) => rules.wholeNumber(v, 40, 150),
              ),
            ),
          ],
        ),
        if (_bpError != null) StatusBanner(kind: StatusKind.warn, message: _bpError!),
        if (_highBp) StatusBanner(kind: StatusKind.danger, message: t.highBloodPressure),
        DateField(
          label: t.nextVisitLabel,
          value: _next,
          errorText: _nextError,
          firstDate: today,
          lastDate: today.add(const Duration(days: 120)),
          onChanged: (d) => setState(() {
            _next = d;
            _nextTouched = true;
            _nextError = null;
          }),
        ),
        LabeledField(label: t.notesOptional, controller: _notes),
      ],
      buttons: [PrimaryButton(label: t.save, loading: _busy, onPressed: _mother == null ? null : _save)],
    );
  }
}
