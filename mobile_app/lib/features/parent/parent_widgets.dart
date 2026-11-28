import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/platform/phone_dialer.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../l10n/l10n.dart';
import 'home/mother_view_model.dart';

/// Round initials of each child; tap to switch (blue boys, pink girls).
/// Hidden when there is only one child.
class ChildSwitcher extends StatelessWidget {
  const ChildSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MotherViewModel>();
    if (vm.children.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        children: [
          for (final c in vm.children)
            Semantics(
              button: true,
              selected: c.child.id == vm.selected?.child.id,
              label: c.child.name,
              child: GestureDetector(
                onTap: () => vm.select(c.child.id),
                child: ChildAvatar(child: c.child, selected: c.child.id == vm.selected?.child.id),
              ),
            ),
        ],
      ),
    );
  }
}

class ChildAvatar extends StatelessWidget {
  const ChildAvatar({super.key, required this.child, this.selected = false, this.size = 40});
  final Child child;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final boy = child.sex == Sex.boy;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: boy ? AppColors.boyLight : AppColors.girlLight,
        border: Border.all(
            color: selected ? (boy ? AppColors.boyText : AppColors.girlText) : Colors.transparent, width: 2.5),
      ),
      child: Text(child.name.isEmpty ? '?' : child.name.characters.first.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w800, color: boy ? AppColors.boyText : AppColors.girlText)),
    );
  }
}

/// Red "Call 1990" button: opens the dialler with the ambulance number.
class Call1990Button extends StatelessWidget {
  const Call1990Button({super.key, this.dialer = const PhoneDialer()});
  final PhoneDialer dialer;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.call_rounded),
      label: Text(t.call1990, style: const TextStyle(fontWeight: FontWeight.w800)),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        if (!await dialer.dial(PhoneDialer.ambulance)) {
          messenger.showSnackBar(SnackBar(content: Text(t.dialFailed)));
        }
      },
    );
  }
}

/// White rounded card with a title, used on every mother screen.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.title, this.onTap, this.color});
  final String? title;
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: color ?? AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Row(children: [
                      Expanded(child: Text(title!, style: Theme.of(context).textTheme.titleMedium)),
                      if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.muted),
                    ]),
                  if (title != null) const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
}

/// Danger signs card with the 1990 button (child or pregnancy signs).
class DangerSignsCard extends StatelessWidget {
  const DangerSignsCard({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => InfoCard(
        color: AppColors.dangerLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(body),
            const SizedBox(height: 12),
            const Call1990Button(),
          ],
        ),
      );
}
