import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A bold label above a large text field, as in every form of the design.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.prefixText,
    this.helper,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  /// e.g. `+94` before a phone number.
  final String? prefixText;

  /// Small grey line under the field.
  final String? helper;
  final ValueChanged<String>? onChanged;

  /// Numbers with a decimal point (weights, heights).
  static const decimal = TextInputType.numberWithOptions(decimal: true);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(hintText: hint, prefixText: prefixText, helperText: helper),
        ),
      ],
    );
  }
}
