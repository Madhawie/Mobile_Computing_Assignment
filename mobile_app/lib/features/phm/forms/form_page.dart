import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';

/// Same frame for every PHM form: back button and title on top, fields in
/// the middle (scrolls above the keyboard), main button at the bottom.
class FormPage extends StatelessWidget {
  const FormPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.formKey,
    required this.fields,
    required this.buttons,
    this.message,
  });

  final String title;
  final String? subtitle;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final List<Widget> buttons;

  /// A problem with the whole form (e.g. number already registered), shown
  /// just above the buttons so it is visible however far the form scrolled.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              ScreenHeader(title: title, subtitle: subtitle, onBack: () => context.pop()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  children: [
                    for (final f in fields) ...[f, const SizedBox(height: 14)],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (message != null) ...[
                      StatusBanner(kind: StatusKind.warn, message: message!),
                      const SizedBox(height: 10),
                    ],
                    for (final (i, b) in buttons.indexed) ...[if (i > 0) const SizedBox(height: 8), b],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// After saving: short note that the record is on the phone, then go back.
void savedAndClose(BuildContext context, {Object? result = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).savedOnPhone)),
  );
  context.pop(result);
}
