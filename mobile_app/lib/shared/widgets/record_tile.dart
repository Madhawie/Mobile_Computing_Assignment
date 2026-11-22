import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// A white rounded row for lists of mothers and children:
/// first-letter circle, name, one grey detail line, optional chip, arrow.
class RecordTile extends StatelessWidget {
  const RecordTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.avatarBackground,
    this.avatarForeground,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  /// e.g. a [StatusChip] or a "not sent yet" icon.
  final Widget? trailing;

  /// Defaults to the role colour. Children use blue / pink.
  final Color? avatarBackground;
  final Color? avatarForeground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = title.isEmpty ? '?' : title.characters.first.toUpperCase();
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: avatarBackground ?? scheme.primaryContainer,
                child: Text(letter,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: avatarForeground ?? scheme.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
              if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
