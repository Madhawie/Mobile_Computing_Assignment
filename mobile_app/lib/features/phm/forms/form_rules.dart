import '../../../l10n/l10n.dart';
import '../phm_rules.dart';

/// Checks and defaults for the PHM forms. They return the error text to show
/// under a field, or null when the value is fine. Ranges are wide on purpose:
/// they catch typing mistakes (72 instead of 7.2), not clinical judgement.
class FormRules {
  FormRules(this.t);

  final AppLocalizations t;

  /// `7,4` and `7.4` both work (Sinhala / Tamil keyboards may give a comma).
  static double? parseNumber(String? text) =>
      text == null ? null : double.tryParse(text.trim().replaceAll(',', '.'));

  String? required(String? v) => (v == null || v.trim().isEmpty) ? t.requiredField : null;

  String? number(String? v, num min, num max, {bool optional = false}) {
    if (v == null || v.trim().isEmpty) return optional ? null : t.requiredField;
    final n = parseNumber(v);
    if (n == null || n < min || n > max) return t.numberBetween('$min', '$max');
    return null;
  }

  String? wholeNumber(String? v, int min, int max) {
    final e = number(v, min, max);
    if (e != null) return e;
    return parseNumber(v)! % 1 == 0 ? null : t.numberBetween('$min', '$max');
  }

  String? notFuture(DateTime? d, DateTime today) =>
      d != null && dateOnly(d).isAfter(dateOnly(today)) ? t.dateInFuture : null;

  /// Blood pressure: both numbers in range and top higher than bottom.
  String? bloodPressure(String? top, String? bottom) {
    final a = parseNumber(top), b = parseNumber(bottom);
    if (a == null || b == null) return null; // the field checks report this
    return a > b ? null : t.bpOrder;
  }

  // ------------------------------------------------------------ defaults

  /// Due date from weeks pregnant (40 weeks in all).
  static DateTime dueDateFromWeeks(int weeks, DateTime today) =>
      dateOnly(today).add(Duration(days: (40 - weeks) * 7));

  /// Usual antenatal spacing: every 4 weeks until 28 weeks, every 2 weeks
  /// until 36, then weekly. Only a suggestion; the PHM can change it.
  /// (Check against the current FHB antenatal schedule before release.)
  static DateTime suggestedNextVisit(int weeks, DateTime visitDate) =>
      dateOnly(visitDate).add(Duration(days: weeks < 28 ? 28 : weeks < 36 ? 14 : 7));
}

/// Vaccines of the national schedule (docs/requirements/README.md §2; verify
/// against the latest Epidemiology Unit circular).
const vaccines = ['BCG', 'Pentavalent', 'OPV', 'fIPV', 'MMR', 'Live JE', 'DTP', 'DT'];
