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
DateTime parseTimestamp(Object? s) => DateTime.parse(s as String).toUtc();

/// JSON may give `7` instead of `7.0`; accept both.
double toDouble(Object? v) => (v as num).toDouble();

double? toDoubleOrNull(Object? v) => v == null ? null : (v as num).toDouble();

/// SQLite has no bool type: stored as 0 / 1.
bool intToBool(Object? v) => v == 1 || v == true;

int boolToInt(bool v) => v ? 1 : 0;
