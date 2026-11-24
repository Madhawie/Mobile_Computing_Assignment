import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';
import '../../shared/widgets/widgets.dart';
import 'phm_rules.dart';

/// Turns dates, ages and due dates into short text in the chosen language.
class PhmFormat {
  PhmFormat(BuildContext context)
      : t = AppLocalizations.of(context),
        _locale = Localizations.localeOf(context).toString();

  final AppLocalizations t;
  final String _locale;

  /// `24 Nov` (this year) or `24 Nov 2025`.
  String date(DateTime d, {DateTime? today}) {
    final now = today ?? DateTime.now();
    return (d.year == now.year ? DateFormat.MMMd(_locale) : DateFormat.yMMMd(_locale)).format(d);
  }

  /// `7 months` under 2 years, `2 y 3 m` after.
  String age(DateTime dob, DateTime today) {
    final m = ageInMonths(dob, today);
    return m < 24 ? t.ageMonths(m) : t.ageYears(m ~/ 12, m % 12);
  }

  String kg(double v) => t.kgValue(NumberFormat('0.0#', _locale).format(v));

  /// `3 days late` (red), `Due today` (orange), `In 4 days` (green).
  (String, StatusKind) due(Due d) {
    if (d.overdue) return (t.daysLate(d.daysLate), StatusKind.danger);
    if (d.isToday) return (t.dueTodayLabel, StatusKind.warn);
    return (t.dueInDays(-d.daysLate), StatusKind.good);
  }
}
