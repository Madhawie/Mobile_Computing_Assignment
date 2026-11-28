import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../../phm/phm_format.dart';
import '../home/mother_view_model.dart';
import '../parent_widgets.dart';
import 'advice_content.dart';

/// P5 · Advice by age: feeding, play and safety for the child's age band,
/// and the danger signs with the 1990 button. From an asset, so offline.
class AdviceScreen extends StatefulWidget {
  const AdviceScreen({super.key});

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends State<AdviceScreen> {
  /// Band picked by hand; null = the selected child's own band.
  String? _bandId;
  String? _forChild;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final vm = context.watch<MotherViewModel>();
    final f = PhmFormat(context);
    final lang = Localizations.localeOf(context).languageCode;
    final s = vm.selected;
    if (_forChild != s?.child.id) {
      _forChild = s?.child.id; // a new child: back to her own band
      _bandId = null;
    }

    return SafeArea(
      child: FutureBuilder<AdviceContent>(
        future: AdviceContent.load(),
        builder: (context, snap) {
          final advice = snap.data;
          if (advice == null) return const Center(child: CircularProgressIndicator());
          final own = advice.groupFor(s?.ageMonths ?? 0);
          final group = advice.groups.where((g) => g.id == _bandId).firstOrNull ?? own;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Text(t.tabAdvice, style: Theme.of(context).textTheme.headlineMedium),
              if (s != null)
                Text(t.adviceFor(s.child.name, f.age(s.child.dateOfBirth, vm.today)),
                    style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              const ChildSwitcher(),
              ChoiceToggle<String>(
                options: [for (final g in advice.groups) ChoiceOption(g.id, g.label.of(lang))],
                selected: group.id,
                onChanged: (id) => setState(() => _bandId = id),
              ),
              const SizedBox(height: 12),
              for (final c in group.cards)
                InfoCard(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(switch (c.kind) {
                      AdviceKind.feeding => Icons.restaurant_rounded,
                      AdviceKind.play => Icons.toys_rounded,
                      AdviceKind.safety => Icons.health_and_safety_rounded,
                    }, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.title.of(lang), style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(c.body.of(lang)),
                      ]),
                    ),
                  ]),
                ),
              DangerSignsCard(title: advice.dangerSigns.title.of(lang), body: advice.dangerSigns.body.of(lang)),
              Text(advice.source, style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        },
      ),
    );
  }
}
