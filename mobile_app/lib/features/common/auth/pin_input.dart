import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';

/// Big digit box for PINs and SMS codes. Calls [onCompleted] as soon as
/// [length] digits are typed, so there is no extra button to press.
class PinInput extends StatefulWidget {
  const PinInput({
    super.key,
    required this.length,
    required this.onCompleted,
    this.obscure = true,
    this.enabled = true,
    this.semanticLabel,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final bool obscure;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<PinInput> createState() => PinInputState();
}

class PinInputState extends State<PinInput> {
  final _controller = TextEditingController();

  /// Empties the box (after a wrong PIN or code).
  void clear() => _controller.clear();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        autofocus: true,
        obscureText: widget.obscure,
        obscuringCharacter: '●',
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: widget.length,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
            fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 18, color: AppColors.text),
        decoration: const InputDecoration(counterText: ''),
        onChanged: (v) {
          if (v.length == widget.length) widget.onCompleted(v);
        },
      ),
    );
  }
}
