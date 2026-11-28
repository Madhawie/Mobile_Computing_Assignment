import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../../phm/growth_record/growth_zone.dart';
import '../../phm/phm_format.dart';
import '../home/mother_view_model.dart';
import '../parent_widgets.dart';
import 'growth_chart.dart';

/// P3 · Growth: weight-for-age chart with the WHO zones, the zone of the
/// latest weight in plain words, and every measurement.
class GrowthScreen extends StatelessWidget {
  const GrowthScreen({super.key, this.reference});

  /// For tests; the app loads the WHO table from assets.
  final Future<GrowthReference?>? reference;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vm = context.watch<MotherViewModel>();
    final f = PhmFormat(context);
    final s = vm.selected;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(t.tabGrowth, style: Theme.of(context).textTheme.headlineMedium),
          if (s != null)
            Text('${s.child.name} · ${s.child.sex == Sex.boy ? t.boy : t.girl} · ${f.age(s.child.dateOfBirth, vm.today)}',
                style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          const ChildSwitcher(),
          if (s != null)
            FutureBuilder<GrowthReference?>(
              future: reference ?? GrowthReference.load(),
              builder: (context, snap) {
                final ref = snap.data;
                final latest = s.latest;
                final z = latest == null || ref == null
                    ? null
                    : ref.weightForAgeZ(s.child.sex, s.child.dateOfBirth, latest.measuredOn, latest.weightKg);
                final zone = z == null ? null : zoneFor(z);
                final zoneText = switch (zone) {
                  GrowthZone.normal => t.motherZoneNormal,
                  GrowthZone.moderate => t.motherZoneModerate,
                  GrowthZone.severe => t.motherZoneSevere,
                  GrowthZone.overweight => t.motherZoneOverweight,
                  null => null,
                };
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  InfoCard(
                    title: t.weightForAge,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      GrowthChart(
                        sex: s.child.sex,
                        dob: s.child.dateOfBirth,
                        measurements: s.growth,
                        reference: ref,
                        today: vm.today,
                        semanticLabel: [
                          t.weightForAge,
                          if (latest != null) t.latestWeight(f.kg(latest.weightKg), f.date(latest.measuredOn)),
                          ?zoneText,
                        ].join('. '),
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 12, runSpacing: 4, children: [
                        _Legend(AppColors.goodLight, t.legendNormal),
                        _Legend(AppColors.warnLight, t.legendBelow2),
                        _Legend(AppColors.dangerLight, t.legendBelow3),
                        _Legend(AppColors.background, t.legendAbove2),
                      ]),
                    ]),
                  ),
                  if (zoneText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StatusBanner(
                        kind: switch (zone!) {
                          GrowthZone.normal => StatusKind.good,
                          GrowthZone.severe => StatusKind.danger,
                          _ => StatusKind.warn,
                        },
                        message: zoneText,
                      ),
                    ),
                ]);
              },
            ),
          if (s != null) ...[
            Text(t.measurements, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (s.growth.isEmpty) Text(t.noMeasurements),
            for (final m in s.growth.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RecordTile(
                  title: [f.kg(m.weightKg), if (m.heightCm != null) '${m.heightCm!.toStringAsFixed(0)} cm'].join(' · '),
                  subtitle: [f.date(m.measuredOn), if (m.notes?.isNotEmpty ?? false) m.notes!].join(' · '),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]);
}
