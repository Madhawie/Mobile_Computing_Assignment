import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../../phm/phm_format.dart';
import '../advice/advice_content.dart';
import '../parent_widgets.dart';
import '../vaccines/vaccine_schedule.dart';
import 'mother_view_model.dart';

/// P1 · Mother home: pregnancy, children, what is coming up, a tip, 1990.
class MotherHomeScreen extends StatelessWidget {
  const MotherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vm = context.watch<MotherViewModel>();
    final auth = context.watch<AuthController>();
    final f = PhmFormat(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Row(children: [
              Expanded(
                child: Text(t.helloName(vm.mother?.fullName ?? auth.session?.user.name ?? ''),
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              IconButton(tooltip: t.signOut, icon: const Icon(Icons.logout_rounded), onPressed: auth.signOut),
            ]),
            const SizedBox(height: 12),
            if (vm.loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (vm.motherId == null)
              StatusBanner(kind: StatusKind.warn, message: t.notLinked)
            else if (vm.mother == null && vm.children.isEmpty)
              StatusBanner(kind: StatusKind.warn, message: t.noRecordsYet)
            else ...[
              if (vm.weeksPregnantNow case final weeks?)
                InfoCard(
                  title: t.myPregnancy,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  onTap: () => context.go(Routes.motherPregnancy),
                  child: Text([
                    t.weeksPregnantNow(weeks),
                    if (vm.mother!.dueDate != null) t.dueOn(f.date(vm.mother!.dueDate!)),
                  ].join(' · ')),
                ),
              if (vm.children.isNotEmpty) _Heading(t.myChildren),
              for (final c in vm.children) _ChildTile(summary: c, format: f),
              if (vm.comingUp.isNotEmpty) ...[
                _Heading(t.comingUp),
                InfoCard(
                  child: Column(children: [for (final u in vm.comingUp.take(4)) _UpcomingRow(item: u, format: f)]),
                ),
              ],
              if (vm.children.isNotEmpty) _TipCard(summary: vm.children.last), // youngest last (by birth)
            ],
            const SizedBox(height: 8),
            const Call1990Button(),
          ],
        ),
      ),
    );
  }
}

/// "Pentavalent 1 · OPV 1 · fIPV 1".
String dosesText(List<VaccineDose> doses) => doses.map((d) => d.label).join(' · ');

class _ChildTile extends StatelessWidget {
  const _ChildTile({required this.summary, required this.format});
  final ChildSummary summary;
  final PhmFormat format;

  @override
  Widget build(BuildContext context) {
    final t = format.t;
    final c = summary.child;
    final next = summary.card.next;
    final line = [
      format.age(c.dateOfBirth, context.read<MotherViewModel>().today),
      if (next != null) '${dosesText(next.missing)} · ${format.date(next.dueOn)}'
      else if (summary.nextWeighing != null) '${t.weightCheck} · ${format.date(summary.nextWeighing!.date)}',
    ].join(' · ');
    final boy = c.sex == Sex.boy;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RecordTile(
        title: c.name,
        subtitle: line,
        avatarBackground: boy ? AppColors.boyLight : AppColors.girlLight,
        avatarForeground: boy ? AppColors.boyText : AppColors.girlText,
        trailing: next?.status == StepStatus.late ? StatusChip(kind: StatusKind.danger, label: t.lateChip) : null,
        onTap: () => context.go(Routes.motherChild(c.id)),
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.item, required this.format});
  final Upcoming item;
  final PhmFormat format;

  @override
  Widget build(BuildContext context) {
    final t = format.t;
    final locale = Localizations.localeOf(context).toString();
    final what = switch (item.kind) {
      UpcomingKind.vaccine => dosesText(item.doses),
      UpcomingKind.weighing => t.weightCheck,
      UpcomingKind.antenatal => t.antenatalClinic,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(DateFormat.MMM(locale).format(item.date), style: Theme.of(context).textTheme.bodySmall),
            Text('${item.date.day}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(what, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (item.child != null) Text(item.child!.name, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ]),
    );
  }
}

/// The feeding tip for the youngest child's age; opens Advice.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.summary});
  final ChildSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return FutureBuilder<AdviceContent>(
      future: AdviceContent.load(),
      builder: (context, snap) {
        final advice = snap.data;
        if (advice == null) return const SizedBox.shrink();
        final card = advice.groupFor(summary.ageMonths).cards.first;
        return InfoCard(
          title: t.tipFor(summary.child.name),
          onTap: () {
            context.read<MotherViewModel>().select(summary.child.id);
            context.go(Routes.motherAdvice);
          },
          child: Text(card.title.of(lang)),
        );
      },
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
