import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../../phm/phm_format.dart';
import '../home/mother_home_screen.dart';
import '../home/mother_view_model.dart';
import '../parent_widgets.dart';
import 'vaccine_schedule.dart';

/// P4 · Vaccination card: every visit of the national schedule with its
/// date (from the date of birth) and whether it was given.
class VaccinesScreen extends StatelessWidget {
  const VaccinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vm = context.watch<MotherViewModel>();
    final f = PhmFormat(context);
    final s = vm.selected;
    final card = s?.card;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(t.tabVaccines, style: Theme.of(context).textTheme.headlineMedium),
          if (s != null)
            Text('${s.child.name} · ${s.child.sex == Sex.boy ? t.boy : t.girl} · ${f.age(s.child.dateOfBirth, vm.today)}',
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          const ChildSwitcher(),
          if (card != null) ...[
            InfoCard(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(t.vaccinesGivenOf(card.givenCount, card.steps.length),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  StatusChip(
                    kind: card.onTrack ? StatusKind.good : StatusKind.danger,
                    label: card.onTrack ? t.onTrack : t.lateChip,
                  ),
                ]),
                const SizedBox(height: 4),
                Text(switch (card.next) {
                  final n? => t.nextVaccine(dosesText(n.missing), f.date(n.dueOn)),
                  null => t.allVaccinesGiven,
                }),
              ]),
            ),
            if (!card.onTrack) ...[
              StatusBanner(kind: StatusKind.danger, message: t.vaccinesLate),
              const SizedBox(height: 12),
            ],
            for (final step in card.steps) _StepRow(step: step, format: f),
            const SizedBox(height: 8),
            Text(t.scheduleSource, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.format});
  final CardStep step;
  final PhmFormat format;

  @override
  Widget build(BuildContext context) {
    final t = format.t;
    final months = step.step.months;
    final age = months == 0 ? t.atBirth : months < 24 ? t.atMonths(months) : t.atYears(months ~/ 12);
    final locale = Localizations.localeOf(context).toString();
    final (Widget trailing, Color dot) = switch (step.status) {
      StepStatus.given => (
          Text(t.givenOn(format.date(step.givenOn ?? step.dueOn)), style: const TextStyle(color: AppColors.good)),
          AppColors.good
        ),
      StepStatus.due => (StatusChip(kind: StatusKind.warn, label: t.dueOn(format.date(step.dueOn))), AppColors.warn),
      StepStatus.late => (
          StatusChip(kind: StatusKind.danger, label: t.lateSince(format.date(step.dueOn))),
          AppColors.danger
        ),
      StepStatus.upcoming => (
          Text(DateFormat.yMMM(locale).format(step.dueOn), style: Theme.of(context).textTheme.bodySmall),
          AppColors.border
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(step.status == StepStatus.given ? Icons.check_circle_rounded : Icons.circle_outlined, color: dot, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(age, style: Theme.of(context).textTheme.bodySmall),
                Text(dosesText(step.step.doses), style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
            ),
            Flexible(child: Align(alignment: Alignment.centerRight, child: trailing)),
          ]),
        ),
      ),
    );
  }
}
