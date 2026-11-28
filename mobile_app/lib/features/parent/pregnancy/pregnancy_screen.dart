import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../../phm/phm_format.dart';
import '../advice/advice_content.dart';
import '../home/mother_view_model.dart';
import '../parent_widgets.dart';

/// P6 · My pregnancy: weeks, due date, next clinic visit, the PHM's visit
/// records, and the pregnancy danger signs with the 1990 button.
class PregnancyScreen extends StatelessWidget {
  const PregnancyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vm = context.watch<MotherViewModel>();
    final f = PhmFormat(context);
    final lang = Localizations.localeOf(context).languageCode;
    final m = vm.mother;
    final weeks = vm.weeksPregnantNow;

    return SafeArea(
      child: Column(children: [
        ScreenHeader(title: t.myPregnancy, onBack: () => context.go(Routes.motherHome)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              if (weeks == null)
                StatusBanner(kind: StatusKind.good, message: t.notPregnant)
              else
                InfoCard(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.weeksPregnantNow(weeks), style: Theme.of(context).textTheme.titleLarge),
                    if (m?.dueDate != null) Text(t.dueOn(f.date(m!.dueDate!))),
                    if (vm.nextAntenatal case final next?) Text(t.nextVisitOn(f.date(next.date))),
                  ]),
                ),
              FutureBuilder<AdviceContent>(
                future: AdviceContent.load(),
                builder: (context, snap) => snap.data == null
                    ? const SizedBox.shrink()
                    : DangerSignsCard(
                        title: snap.data!.pregnancyDangerSigns.title.of(lang),
                        body: snap.data!.pregnancyDangerSigns.body.of(lang)),
              ),
              Text(t.clinicVisits, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (vm.visits.isEmpty) Text(t.noVisitsYet),
              for (final v in vm.visits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RecordTile(
                    title: '${f.date(v.visitDate)} · ${t.weeksPregnantNow(v.gestationWeeks)}',
                    subtitle: [f.kg(v.weightKg), t.bpValue(v.bpSystolic, v.bpDiastolic), if (v.notes?.isNotEmpty ?? false) v.notes!]
                        .join(' · '),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
