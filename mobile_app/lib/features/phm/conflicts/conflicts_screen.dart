import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import 'conflicts_view_model.dart';

/// P8 · Check a record: each flagged conflict with both values and two
/// buttons. Nothing was lost; the PHM only chooses which value stays.
class ConflictsScreen extends StatelessWidget {
  const ConflictsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vm = context.watch<ConflictsViewModel>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: t.checkRecords, onBack: () => context.pop()),
            Expanded(
              child: vm.loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: vm.refresh,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: [
                          if (vm.offline) ...[
                            StatusBanner(kind: StatusKind.warn, message: t.shownFromPhone),
                            const SizedBox(height: 12),
                          ],
                          if (vm.items.isEmpty)
                            StatusBanner(kind: StatusKind.good, message: t.nothingToCheck)
                          else
                            for (final item in vm.items) ...[
                              _ConflictCard(item: item),
                              const SizedBox(height: 12),
                            ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({required this.item});
  final ConflictItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vm = context.read<ConflictsViewModel>();
    final c = item.conflict;
    final busy = context.watch<ConflictsViewModel>().deciding == c.id;

    Future<void> decide(bool keepCurrent) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await vm.decide(c, keepCurrent: keepCurrent);
        messenger.showSnackBar(SnackBar(content: Text(t.decisionSaved)));
      } on ApiFailure {
        messenger.showSnackBar(SnackBar(content: Text(t.needSignalToDecide)));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.recordLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(c.kind == Conflict.deleteVsUpdate ? t.conflictDeleteVsUpdate : t.conflictSameField,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            for (final f in c.fields) _FieldRow(field: f, myDeviceId: vm.deviceId),
            const SizedBox(height: 10),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else ...[
              PrimaryButton(label: t.keepCurrent, onPressed: () => decide(true)),
              const SizedBox(height: 8),
              SecondaryButton(label: t.useOtherValue, onPressed: () => decide(false)),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field, required this.myDeviceId});
  final ConflictField field;
  final String? myDeviceId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    String show(Object? v) => switch (v) {
          null || '' => t.emptyValue,
          true when field.field == 'deleted' => t.deletedLabel,
          _ => '$v',
        };
    final source = field.lostDeviceId != null && field.lostDeviceId == myDeviceId ? t.fromYourPhone : t.fromOtherDevice;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_fieldLabel(t, field.field), style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(t.valueNow(show(field.kept)), style: const TextStyle(color: AppColors.good, fontWeight: FontWeight.w700)),
          Text(t.otherValueFrom(source, show(field.lost)), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Field names in the user's language where the forms already have them.
String _fieldLabel(AppLocalizations t, String field) => switch (field) {
      'fullName' => t.fullName,
      'phone' => t.yourMobileNumber,
      'age' => t.ageLabel,
      'address' => t.addressLabel,
      'gestationWeeks' => t.weeksPregnant,
      'dueDate' => t.dueDateLabel,
      'name' => t.childName,
      'dateOfBirth' => t.dateOfBirth,
      'birthWeightKg' => t.birthWeightKg,
      'weightKg' => t.weightKgLabel,
      'heightCm' => t.heightCmLabel,
      'notes' => t.notesOptional,
      'nextVisit' => t.nextVisitLabel,
      'deleted' => t.deletedLabel,
      _ => field,
    };
