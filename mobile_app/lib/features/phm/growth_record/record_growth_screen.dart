import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/app_repositories.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../forms/form_page.dart';
import '../forms/form_rules.dart';
import '../forms/phm_entry.dart';
import '../phm_format.dart';
import '../phm_rules.dart';
import 'growth_zone.dart';

/// P4 · Record growth. As soon as a weight is typed, the CHDR zone for the
/// child's sex and age is shown (green / orange / red), like plotting the
/// dot on the paper chart. Saved offline.
class RecordGrowthScreen extends StatefulWidget {
  const RecordGrowthScreen({
    super.key,
    required this.childId,
    this.reference,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final String childId;

  /// For tests; the app loads the WHO table from assets.
  final GrowthReference? reference;
  final DateTime Function() _clock;

  @override
  State<RecordGrowthScreen> createState() => _RecordGrowthScreenState();
}

class _RecordGrowthScreenState extends State<RecordGrowthScreen> {
  final _form = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _notes = TextEditingController();
  Child? _child;
  GrowthReference? _reference;
  bool _referenceChecked = false;
  late DateTime _date = dateOnly(widget._clock());
  String? _dateError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    context.read<AppRepositories>().children.getById(widget.childId).then((c) {
      if (mounted) setState(() => _child = c);
    });
    if (widget.reference != null) {
      _reference = widget.reference;
      _referenceChecked = true;
    } else {
      GrowthReference.load().then((r) {
        if (mounted) {
          setState(() {
            _reference = r;
            _referenceChecked = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Zone for the typed weight, or null while it cannot be worked out.
  GrowthZone? get _zone {
    final w = FormRules.parseNumber(_weight.text);
    final c = _child;
    if (w == null || w <= 0 || c == null || _reference == null) return null;
    final z = _reference!.weightForAgeZ(c.sex, c.dateOfBirth, _date, w);
    return z == null ? null : zoneFor(z);
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final c = _child;
    if (c == null) return;
    setState(() => _dateError = FormRules(t).notFuture(_date, widget._clock()) ??
        (_date.isBefore(dateOnly(c.dateOfBirth)) ? t.beforeBirth : null));
    if (!_form.currentState!.validate() || _dateError != null) return;

    setState(() => _busy = true);
    await PhmEntry(context.read<AppRepositories>()).recordGrowth(
      childId: c.id,
      measuredOn: _date,
      weightKg: FormRules.parseNumber(_weight.text)!,
      heightCm: FormRules.parseNumber(_height.text),
      notes: _notes.text,
    );
    if (mounted) savedAndClose(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final rules = FormRules(t);
    final today = widget._clock();
    final c = _child;
    final f = PhmFormat(context);

    return FormPage(
      title: t.recordGrowth,
      subtitle: c == null ? null : '${c.name} · ${c.sex == Sex.boy ? t.boy : t.girl} · ${f.age(c.dateOfBirth, today)}',
      formKey: _form,
      fields: [
        DateField(
          label: t.dateLabel,
          value: _date,
          errorText: _dateError,
          firstDate: c?.dateOfBirth ?? DateTime(today.year - 5),
          lastDate: today,
          onChanged: (d) => setState(() {
            _date = d;
            _dateError = null;
          }),
        ),
        LabeledField(
          label: t.weightKgLabel,
          controller: _weight,
          keyboardType: LabeledField.decimal,
          onChanged: (_) => setState(() {}),
          validator: (v) => rules.number(v, 0.5, 40),
        ),
        if (FormRules.parseNumber(_weight.text) != null && _referenceChecked) _ZoneBanner(zone: _zone),
        LabeledField(
          label: t.heightCmLabel,
          controller: _height,
          keyboardType: LabeledField.decimal,
          validator: (v) => rules.number(v, 30, 130, optional: true),
        ),
        LabeledField(label: t.notesOptional, controller: _notes),
      ],
      buttons: [PrimaryButton(label: t.save, loading: _busy, onPressed: c == null ? null : _save)],
    );
  }
}

class _ZoneBanner extends StatelessWidget {
  const _ZoneBanner({required this.zone});
  final GrowthZone? zone;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (kind, text) = switch (zone) {
      GrowthZone.normal => (StatusKind.good, t.zoneNormal),
      GrowthZone.moderate => (StatusKind.warn, t.zoneModerate),
      GrowthZone.severe => (StatusKind.danger, t.zoneSevere),
      GrowthZone.overweight => (StatusKind.warn, t.zoneOverweight),
      null => (StatusKind.warn, t.zoneUnavailable),
    };
    return StatusBanner(kind: kind, message: text);
  }
}
