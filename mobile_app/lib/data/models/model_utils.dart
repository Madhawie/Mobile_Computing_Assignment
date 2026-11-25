/// Small conversion helpers shared by the models.
library;

/// `2026-11-20` – used for dates without a time (date of birth, visit date).
String formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime parseDate(String s) => DateTime.parse(s);

String? formatDateOrNull(DateTime? d) => d == null ? null : formatDate(d);

DateTime? parseDateOrNull(Object? s) => s == null ? null : parseDate(s as String);

/// Timestamps are always kept in UTC.
///
/// A time with no zone (`2026-11-20T08:15:30`) is read as UTC, not as phone
/// time: SQL Server's `datetime2` keeps no zone, so the .NET API sends its
/// UTC times without the `Z`. Read as local time in Sri Lanka they would be
/// 5 h 30 min wrong, and S1 (which uploads every record again) would move
/// `updatedAt` back by that much on every sync.
DateTime parseTimestamp(Object? s) {
  final text = s as String;
  return DateTime.parse(_hasZone.hasMatch(text) ? text : '${text}Z').toUtc();
}

/// Ends in `Z` or `+hh:mm` / `-hhmm` after the time part.
final _hasZone = RegExp(r'T.*(Z|[+-]\d\d:?\d\d)$', caseSensitive: false);

/// JSON may give `7` instead of `7.0`; accept both.
double toDouble(Object? v) => (v as num).toDouble();

double? toDoubleOrNull(Object? v) => v == null ? null : (v as num).toDouble();

/// SQLite has no bool type: stored as 0 / 1.
bool intToBool(Object? v) => v == 1 || v == true;

int boolToInt(bool v) => v ? 1 : 0;
