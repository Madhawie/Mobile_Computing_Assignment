import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// One option of a [ChoiceToggle]. Colours are optional; Boy / Girl uses the
/// CHDR blue and pink.
class ChoiceOption<T> {
  const ChoiceOption(this.value, this.label, {this.background, this.foreground, this.border});

  final T value;
  final String label;
  final Color? background;
  final Color? foreground;
  final Color? border;
}

/// Big side-by-side buttons for a small choice (Boy / Girl, Pregnant Yes / No).
/// Easier to tap than a dropdown.
class ChoiceToggle<T> extends StatelessWidget {
  const ChoiceToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<ChoiceOption<T>> options;
  final T? selected;
  final ValueChanged<T> onChanged;

  /// Boy / Girl with the CHDR colours.
  static List<ChoiceOption<String>> sexOptions({required String boy, required String girl}) => [
        ChoiceOption('boy', boy,
            background: AppColors.boyLight, foreground: AppColors.boyText, border: AppColors.boyAccent),
        ChoiceOption('girl', girl,
            background: AppColors.girlLight, foreground: AppColors.girlText, border: AppColors.girlAccent),
      ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        for (final (i, o) in options.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _OptionButton(
              label: o.label,
              on: o.value == selected,
              background: o.background ?? Theme.of(context).colorScheme.primaryContainer,
              foreground: o.foreground ?? primary,
              border: o.border ?? primary,
              onTap: () => onChanged(o.value),
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.on,
    required this.background,
    required this.foreground,
    required this.border,
    required this.onTap,
  });

  final String label;
  final bool on;
  final Color background, foreground, border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? background : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: on ? border : AppColors.border, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: on ? foreground : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
