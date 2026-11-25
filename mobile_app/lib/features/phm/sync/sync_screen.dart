import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/sync/sync_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../phm_format.dart';
import 'sync_view_model.dart';

/// P9 · Sync (design M10): offline state, what is waiting, "Send now" and
/// the automatic-sending switch. Everything shown comes from the phone.
class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final sync = context.watch<SyncController>();
    final vm = context.watch<SyncViewModel>();
    final f = PhmFormat(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text(t.syncTab, style: Theme.of(context).textTheme.headlineMedium),
            Text(t.syncSubtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            _StatusCard(sync: sync, format: f),
            if (sync.lastResult != null && !sync.syncing) ...[
              const SizedBox(height: 12),
              sync.lastResult!.success
                  ? StatusBanner(
                      kind: StatusKind.good,
                      message: t.syncDoneSummary(sync.lastResult!.push.sent, sync.lastResult!.pull?.applied ?? 0))
                  : StatusBanner(kind: StatusKind.warn, message: t.syncFailed),
            ],
            const SizedBox(height: 12),
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              child: SwitchListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: Text(t.sendAutomatically, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(t.sendAutomaticallyHelp),
                value: sync.autoSync,
                onChanged: sync.setAutoSync,
              ),
            ),
            if (vm.refused.isNotEmpty) ...[
              _Heading('${t.notAccepted} · ${vm.refused.length}'),
              Text(t.notAcceptedHelp, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              for (final item in vm.refused)
                _PendingTile(item: item, format: f, trailing: const StatusChip(kind: StatusKind.danger, label: '!')),
            ],
            if (vm.waiting.isNotEmpty) ...[
              _Heading('${t.waitingToSend} · ${vm.waiting.length}'),
              for (final item in vm.waiting) _PendingTile(item: item, format: f),
            ],
          ],
        ),
      ),
    );
  }
}

/// Online / offline, how many wait, when last sent, and the button.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.sync, required this.format});

  final SyncController sync;
  final PhmFormat format;

  @override
  Widget build(BuildContext context) {
    final t = format.t;
    final scheme = Theme.of(context).colorScheme;
    final last = sync.lastSyncAt == null
        ? t.neverSynced
        : t.lastSyncAt('${format.date(sync.lastSyncAt!)} ${DateFormat.Hm().format(sync.lastSyncAt!)}');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(sync.online ? Icons.wifi_rounded : Icons.wifi_off_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Text(sync.online ? t.youAreOnline : t.youAreOffline,
                  style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(t.pendingChanges(sync.pending)),
          Text(last, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          PrimaryButton(
            label: sync.syncing ? t.sending : t.sendNow,
            icon: Icons.cloud_upload_rounded,
            loading: sync.syncing,
            onPressed: sync.syncing ? null : sync.sendNow,
          ),
        ],
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.item, required this.format, this.trailing});

  final PendingItem item;
  final PhmFormat format;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = format.t;
    final e = item.entry;
    final kind = switch (e.entity) {
      Mother.entityName => t.kindMother,
      MaternalVisit.entityName => t.kindVisit,
      Child.entityName => t.kindChild,
      GrowthMeasurement.entityName => t.kindGrowth,
      _ => t.kindVaccine,
    };
    final created = e.createdAt.toLocal();
    final now = DateTime.now();
    final when = DateUtils.isSameDay(created, now) ? DateFormat.Hm().format(created) : format.date(created);
    final title = item.name.isEmpty ? kind : '$kind · ${item.name}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RecordTile(
        title: title,
        subtitle: e.op == OutboxOp.delete ? '${t.deletedLabel} · $when' : when,
        trailing: trailing,
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
