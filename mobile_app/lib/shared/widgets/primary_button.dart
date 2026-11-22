import 'package:material_ui/material_ui.dart';

/// The one main action of a screen ("Save child", "Send now").
/// Full width, 54 px high, role colour. Shows a spinner while [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : Text(label);
    return icon == null || loading
        ? FilledButton(onPressed: loading ? null : onPressed, child: child)
        : FilledButton.icon(onPressed: onPressed, icon: Icon(icon, size: 20), label: child);
  }
}

/// A second, quieter action ("Save and add a child").
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      OutlinedButton(onPressed: onPressed, child: Text(label));
}
