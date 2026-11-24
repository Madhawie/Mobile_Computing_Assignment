import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/dev/sample_data.dart';
import '../../../data/repositories/app_repositories.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import 'register_view_model.dart';

/// Debug builds only: fills an empty register with synthetic sample data.
class SampleDataButton extends StatefulWidget {
  const SampleDataButton({super.key});

  @override
  State<SampleDataButton> createState() => _SampleDataButtonState();
}

class _SampleDataButtonState extends State<SampleDataButton> {
  bool _busy = false;

  Future<void> _load() async {
    setState(() => _busy = true);
    final vm = context.read<RegisterViewModel>();
    await loadSampleData(
      context.read<AppRepositories>(),
      areaId: context.read<AuthController>().session?.user.areaId ?? vm.areaId,
      today: DateTime.now(),
    );
    await vm.load();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => SecondaryButton(
        label: AppLocalizations.of(context).loadSampleData,
        onPressed: _busy ? null : _load,
      );
}
