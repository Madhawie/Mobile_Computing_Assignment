import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../data/models/models.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../../phm/phm_format.dart';
import '../home/mother_home_screen.dart';
import '../home/mother_view_model.dart';
import '../parent_widgets.dart';

/// P2 · Child record: the CHDR front page, with links to growth, vaccines
/// and advice for this child.
class ChildRecordScreen extends StatefulWidget {
  const ChildRecordScreen({super.key, required this.childId});
  final String childId;

  @override
  State<ChildRecordScreen> createState() => _ChildRecordScreenState();
}

class _ChildRecordScreenState extends State<ChildRecordScreen> {
  @override
  void initState() {
    super.initState();
    // The tabs show the child chosen here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MotherViewModel>().select(widget.childId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vm = context.watch<MotherViewModel>();
    final f = PhmFormat(context);
    final s = vm.children.where((c) => c.child.id == widget.childId).firstOrNull;

    return SafeArea(
      child: Column(children: [
        ScreenHeader(title: t.childRecord, onBack: () => context.go(Routes.motherHome)),
        Expanded(
          child: s == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    InfoCard(
                      child: Row(children: [
                        ChildAvatar(child: s.child, size: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.child.name, style: Theme.of(context).textTheme.titleLarge),
                            Text([
                              s.child.sex == Sex.boy ? t.boy : t.girl,
                              f.age(s.child.dateOfBirth, vm.today),
                              t.bornOn(f.date(s.child.dateOfBirth)),
                            ].join(' · ')),
                            Text(t.birthWeightValue(f.kg(s.child.birthWeightKg)),
                                style: Theme.of(context).textTheme.bodySmall),
                            if (s.child.chdrNumber != null)
                              Text('${t.chdrNumberLabel}: ${s.child.chdrNumber}',
                                  style: Theme.of(context).textTheme.bodySmall),
                          ]),
                        ),
                      ]),
                    ),
                    InfoCard(
                      title: t.growthChart,
                      onTap: () => context.go(Routes.motherGrowth),
                      child: Text(s.latest == null
                          ? t.noMeasurements
                          : t.latestWeight(f.kg(s.latest!.weightKg), f.date(s.latest!.measuredOn))),
                    ),
                    InfoCard(
                      title: t.tabVaccines,
                      onTap: () => context.go(Routes.motherVaccines),
                      child: Text([
                        t.vaccinesGivenOf(s.card.givenCount, s.card.steps.length),
                        if (s.card.next case final n?) t.nextVaccine(dosesText(n.missing), f.date(n.dueOn)),
                      ].join('\n')),
                    ),
                    InfoCard(
                      title: t.tabAdvice,
                      onTap: () => context.go(Routes.motherAdvice),
                      child: Text(t.adviceFor(s.child.name, f.age(s.child.dateOfBirth, vm.today))),
                    ),
                  ],
                ),
        ),
      ]),
    );
  }
}
