import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/auth/phone_number.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../phm_format.dart';
import 'mother_detail_view_model.dart';

/// P5 · Mother: contact, pregnancy, visits and children on one page.
class MotherDetailScreen extends StatelessWidget {
  const MotherDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vm = context.watch<MotherDetailViewModel>();
    final f = PhmFormat(context);
    final m = vm.mother;

    void back() => context.canPop() ? context.pop() : context.go(Routes.phmRegister);

    return Scaffold(
      body: SafeArea(
        child: vm.loading
            ? const Center(child: CircularProgressIndicator())
            : m == null
                ? Column(children: [
                    ScreenHeader(title: '', onBack: back),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: StatusBanner(kind: StatusKind.warn, message: t.noResults),
                    ),
                  ])
                : RefreshIndicator(
                    onRefresh: vm.load,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        ScreenHeader(
                          title: m.fullName,
                          subtitle: m.areaId,
                          onBack: back,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (vm.hasUnsent) ...[
                                StatusBanner(kind: StatusKind.warn, message: t.notSentYet),
                                const SizedBox(height: 12),
                              ],
                              _Card(children: [
                                _Line(Icons.phone_rounded, PhoneNumber.pretty(m.phone)),
                                _Line(Icons.home_rounded, m.address),
                              ]),
                              if (m.isPregnant) ...[
                                const SizedBox(height: 12),
                                _PregnancyCard(vm: vm, format: f),
                              ],
                              _Section(t.pregnancyVisits),
                              if (vm.visits.isEmpty)
                                Text(t.noVisitsYet, style: Theme.of(context).textTheme.bodySmall)
                              else
                                for (final v in vm.visits) _VisitTile(visit: v, format: f, today: vm.today),
                              _Section(t.childrenTab),
                              if (vm.children.isEmpty)
                                Text(t.noChildrenYet, style: Theme.of(context).textTheme.bodySmall)
                              else
                                for (final c in vm.children)
                                  _ChildTile(
                                    summary: c,
                                    format: f,
                                    today: vm.today,
                                    onTap: () async {
                                      await context.push(Routes.phmRecordGrowth(c.child.id));
                                      await vm.load();
                                    },
                                  ),
                              const SizedBox(height: 8),
                              SecondaryButton(
                                label: t.addChild,
                                onPressed: () async {
                                  await context.push(Routes.phmAddChild(m.id));
                                  await vm.load();
                                },
                              ),
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

class _PregnancyCard extends StatelessWidget {
  const _PregnancyCard({required this.vm, required this.format});
  final MotherDetailViewModel vm;
  final PhmFormat format;

  @override
  Widget build(BuildContext context) {
    final t = format.t;
    final m = vm.mother!;
    final scheme = Theme.of(context).colorScheme;
    final due = vm.nextVisitDue;
    final next = vm.lastVisit?.nextVisit;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.pregnant_woman_rounded, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                m.gestationWeeks == null ? t.pregnancyVisits : t.pregnantWeeks(m.gestationWeeks!),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: scheme.primary),
              ),
            ),
            if (due != null) StatusChip(kind: format.due(due).$2, label: format.due(due).$1),
          ]),
          if (m.dueDate != null) Text(t.dueOn(format.date(m.dueDate!, today: vm.today))),
          if (next != null) Text(t.nextVisitOn(format.date(next, today: vm.today))),
          if (vm.lastVisit?.highBloodPressure ?? false) ...[
            const SizedBox(height: 10),
            StatusBanner(
              kind: StatusKind.danger,
              message: '${t.highBloodPressure} · '
                  '${t.bpValue(vm.lastVisit!.bpSystolic, vm.lastVisit!.bpDiastolic)}',
            ),
          ],
        ],
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.visit, required this.format, required this.today});
  final MaternalVisit visit;
  final PhmFormat format;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final t = format.t;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RecordTile(
        title: format.date(visit.visitDate, today: today),
        subtitle: '${t.weeksShort(visit.gestationWeeks)} · ${format.kg(visit.weightKg)} · '
            '${t.bpValue(visit.bpSystolic, visit.bpDiastolic)}',
        trailing: visit.highBloodPressure
            ? StatusChip(kind: StatusKind.danger, label: t.highBpShort)
            : visit.isDirty
                ? const Icon(Icons.cloud_upload_outlined, size: 20, color: AppColors.muted)
                : null,
      ),
    );
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({required this.summary, required this.format, required this.today, this.onTap});
  final ChildSummary summary;
  final PhmFormat format;
  final DateTime today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = format.t;
    final c = summary.child;
    final boy = c.sex == Sex.boy;
    final weighed = summary.lastGrowth == null
        ? t.neverWeighed
        : '${format.kg(summary.lastGrowth!.weightKg)} · ${format.date(summary.lastGrowth!.measuredOn, today: today)}';
    final w = summary.weighing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RecordTile(
        title: c.name,
        subtitle: '${boy ? t.boy : t.girl} · ${format.age(c.dateOfBirth, today)} · $weighed',
        avatarBackground: boy ? AppColors.boyLight : AppColors.girlLight,
        avatarForeground: boy ? AppColors.boyText : AppColors.girlText,
        onTap: onTap,
        trailing: c.lowBirthWeight
            ? StatusChip(kind: StatusKind.warn, label: t.lowBirthWeightShort)
            : w != null
                ? StatusChip(kind: format.due(w).$2, label: format.due(w).$1)
                : null,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      );
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      );
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
