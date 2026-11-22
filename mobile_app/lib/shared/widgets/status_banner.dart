import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// Green / orange / red, like the CHDR growth zones.
enum StatusKind { good, warn, danger }

/// A coloured message, e.g. "Low birth weight (under 2.5 kg)." or the
/// growth zone after a weight is entered. Has an icon as well as a colour,
/// so it does not rely on colour alone.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.kind, required this.message});

  final StatusKind kind;
  final String message;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (kind) {
      StatusKind.good => (AppColors.goodLight, AppColors.good, Icons.check_circle_outline),
      StatusKind.warn => (AppColors.warnLight, AppColors.warn, Icons.error_outline),
      StatusKind.danger => (AppColors.dangerLight, AppColors.danger, Icons.warning_amber_rounded),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill version for lists ("Watch", "Due today", "3 waiting").
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.kind, required this.label});

  final StatusKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      StatusKind.good => (AppColors.goodLight, AppColors.good),
      StatusKind.warn => (AppColors.warnLight, AppColors.warn),
      StatusKind.danger => (AppColors.dangerLight, AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}
