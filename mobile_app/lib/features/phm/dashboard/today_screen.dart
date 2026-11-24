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
import '../phm_format.dart';
import 'today_view_model.dart';

/// P1 · Today: what the PHM has to do this week, from the phone's own data.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vm = context.watch<TodayViewModel>();
    final user = context.watch<AuthController>().session?.user;
    final f = PhmFormat(context);
    final locale = Localizations.localeOf(context).toString();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text(DateFormat.MMMMEEEEd(locale).format(vm.today), style: Theme.of(context).textTheme.bodySmall),
            Text(t.helloName(user?.name ?? ''), style: Theme.of(context).textTheme.headlineMedium),
            if (user?.areaId != null) Text(user!.areaId!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            _SyncCard(pending: vm.pending, lastSync: vm.lastSync, format: f),
            const SizedBox(height: 20),
            if (vm.loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (vm.error != null)
              StatusBanner(kind: StatusKind.danger, message: t.somethingWrong)
            else ...[
              if (vm.nothingDue) StatusBanner(kind: StatusKind.good, message: t.nothingDue),
              if (vm.dueVisits.isNotEmpty) ...[
                _Heading(t.visitsDue, vm.dueVisits.length),
                for (final v in vm.dueVisits)
                  _Gap(RecordTile(
                    title: v.mother.fullName,
                    subtitle: v.mother.gestationWeeks == null
                        ? v.mother.areaId
                        : t.pregnantWeeks(v.mother.gestationWeeks!),
                    trailing: _DueChip(f.due(v.due)),
                    onTap: () => context.push(Routes.phmMother(v.mother.id)),
                  )),
              ],
              if (vm.dueWeighings.isNotEmpty) ...[
                _Heading(t.childrenToWeigh, vm.dueWeighings.length),
                for (final w in vm.dueWeighings)
                  _Gap(RecordTile(
                    title: w.child.name,
                    subtitle: '${f.age(w.child.dateOfBirth, vm.today)} · ${w.mother.fullName}',
                    avatarBackground: w.child.sex == Sex.boy ? AppColors.boyLight : AppColors.girlLight,
                    avatarForeground: w.child.sex == Sex.boy ? AppColors.boyText : AppColors.girlText,
                    trailing: _DueChip(f.due(w.due)),
                    onTap: () => context.push(Routes.phmMother(w.mother.id)),
                  )),
              ],
              if (vm.watch.isNotEmpty) ...[
                _Heading(t.toWatch, vm.watch.length),
                for (final w in vm.watch)
                  _Gap(RecordTile(
                    title: w.child?.name ?? w.mother.fullName,
                    subtitle: w.child == null ? w.mother.areaId : w.mother.fullName,
                    trailing: StatusChip(
                      kind: StatusKind.warn,
                      label: w.reason == WatchReason.lowBirthWeight ? t.lowBirthWeightShort : t.highBpShort,
                    ),
                    onTap: () => context.push(Routes.phmMother(w.mother.id)),
                  )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Offline status: how many changes wait on this phone, and when it last sent.
class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.pending, required this.lastSync, required this.format});

  final int pending;
  final DateTime? lastSync;
  final PhmFormat format;

  @override
  Widget build(BuildContext context) {
    final t = format.t;
    final scheme = Theme.of(context).colorScheme;
    final last = lastSync == null
        ? t.neverSynced
        : t.lastSyncAt('${format.date(lastSync!)} ${DateFormat.Hm().format(lastSync!)}');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(pending == 0 ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded, color: scheme.primary, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.pendingChanges(pending), style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary)),
                Text(last, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, this.count);
  final String text;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text('$text · $count', style: Theme.of(context).textTheme.titleMedium),
      );
}

class _Gap extends StatelessWidget {
  const _Gap(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: child);
}

class _DueChip extends StatelessWidget {
  const _DueChip(this.value);
  final (String, StatusKind) value;

  @override
  Widget build(BuildContext context) => StatusChip(kind: value.$2, label: value.$1);
}
