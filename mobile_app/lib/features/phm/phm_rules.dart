/// Field-work rules for the PHM screens (docs/requirements/README.md §2).
/// Pure functions of dates, so they are easy to test and to explain.
library;

/// Children are followed by the PHM until their 5th birthday.
const childFollowUpMonths = 60;

/// Up to 2 years a child is weighed every month, from 2 to 5 years every
/// 3 months (CHDR growth monitoring schedule).
int weighingIntervalMonths(int ageMonths) => ageMonths < 24 ? 1 : 3;

/// Whole months between [dob] and [today].
int ageInMonths(DateTime dob, DateTime today) {
  var months = (today.year - dob.year) * 12 + today.month - dob.month;
  if (today.day < dob.day) months--;
  return months < 0 ? 0 : months;
}

/// Same day [months] later; the 31st becomes the last day of a shorter month.
DateTime addMonths(DateTime d, int months) {
  final firstOfTarget = DateTime(d.year, d.month + months, 1);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  return DateTime(firstOfTarget.year, firstOfTarget.month, d.day > lastDay ? lastDay : d.day);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Something the PHM has to do, and by when.
class Due {
  const Due(this.date, this.today);

  final DateTime date;
  final DateTime today;

  bool get overdue => dateOnly(date).isBefore(dateOnly(today));
  bool get isToday => dateOnly(date) == dateOnly(today);

  /// Days late (positive) or days left (negative).
  int get daysLate => dateOnly(today).difference(dateOnly(date)).inDays;
}

/// How far ahead the Today screen looks.
const lookAheadDays = 7;

bool _withinLookAhead(DateTime due, DateTime today) =>
    !dateOnly(due).isAfter(dateOnly(today).add(const Duration(days: lookAheadDays)));

/// Next weighing for a child, or null if none is needed in the next week
/// (or the child is 5 or older). A child never weighed is due one month
/// after birth.
Due? weighingDue({required DateTime dob, DateTime? lastWeighed, required DateTime today}) {
  if (ageInMonths(dob, today) >= childFollowUpMonths) return null;
  final from = lastWeighed ?? dob;
  final next = addMonths(from, weighingIntervalMonths(ageInMonths(dob, from)));
  return _withinLookAhead(next, today) ? Due(next, today) : null;
}

/// Next pregnancy visit for a pregnant mother, or null if not due within a
/// week. With no visit recorded yet, she is due now.
Due? pregnancyVisitDue({required bool isPregnant, DateTime? nextVisit, required DateTime today}) {
  if (!isPregnant) return null;
  final next = nextVisit ?? today;
  return _withinLookAhead(next, today) ? Due(next, today) : null;
}
