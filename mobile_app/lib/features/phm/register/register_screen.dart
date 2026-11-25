import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../phm_format.dart';
import 'register_view_model.dart';

/// M2 · Area register: search and two lists (mothers, children).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key, this.emptyAction});

  /// Shown when the area has no mothers yet (the sample-data button).
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vm = context.watch<RegisterViewModel>();
    final f = PhmFormat(context);

    Future<void> open(String motherId) async {
      await context.push(Routes.phmMother(motherId));
      await vm.load(); // pick up anything changed on the detail screen
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(t.register, style: Theme.of(context).textTheme.headlineMedium)),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      onPressed: () async {
                        await context.push(Routes.phmAddMother);
                        await vm.load();
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: Text(t.addMother),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: vm.search,
                  decoration: InputDecoration(
                    hintText: t.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                ChoiceToggle<RegisterTab>(
                  options: [
                    ChoiceOption(RegisterTab.mothers, t.mothersTab),
                    ChoiceOption(RegisterTab.children, t.childrenTab),
                  ],
                  selected: vm.tab,
                  onChanged: vm.setTab,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.error != null
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: StatusBanner(kind: StatusKind.danger, message: t.somethingWrong),
                      )
                    : vm.isEmpty
                        ? _Empty(action: emptyAction)
                        : RefreshIndicator(
                            onRefresh: vm.load,
                            child: vm.tab == RegisterTab.mothers
                                ? _list(
                                    context,
                                    [
                                      for (final r in vm.mothers)
                                        RecordTile(
                                          title: r.mother.fullName,
                                          subtitle: r.mother.isPregnant && r.mother.gestationWeeks != null
                                              ? '${t.pregnantWeeks(r.mother.gestationWeeks!)} · ${t.childrenCount(r.childCount)}'
                                              : t.childrenCount(r.childCount),
                                          trailing: r.mother.isDirty ? const _NotSentIcon() : null,
                                          onTap: () => open(r.mother.id),
                                        ),
                                    ],
                                  )
                                : _list(
                                    context,
                                    [
                                      for (final r in vm.children)
                                        RecordTile(
                                          title: r.child.name,
                                          subtitle: '${f.age(r.child.dateOfBirth, vm.today)} · ${r.mother.fullName}',
                                          avatarBackground:
                                              r.child.sex == Sex.boy ? AppColors.boyLight : AppColors.girlLight,
                                          avatarForeground:
                                              r.child.sex == Sex.boy ? AppColors.boyText : AppColors.girlText,
                                          trailing: r.child.isDirty ? const _NotSentIcon() : null,
                                          onTap: () => open(r.mother.id),
                                        ),
                                    ],
                                  ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, List<Widget> tiles) {
    if (tiles.isEmpty) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(AppLocalizations.of(context).noResults, textAlign: TextAlign.center),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: tiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => tiles[i],
    );
  }
}

/// Small cloud icon: this record is saved on the phone but not sent yet.
class _NotSentIcon extends StatelessWidget {
  const _NotSentIcon();

  @override
  Widget build(BuildContext context) => Tooltip(
        message: AppLocalizations.of(context).notSentYet,
        child: const Icon(Icons.cloud_upload_outlined, size: 20, color: AppColors.muted),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({this.action});
  final Widget? action;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.groups_rounded, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).emptyRegister, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      );
}
