import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/features/phm/phm_rules.dart';

void main() {
  final today = DateTime(2026, 11, 24);

  group('dates', () {
    test('ageInMonths counts whole months', () {
      expect(ageInMonths(DateTime(2026, 5, 24), today), 6);
      expect(ageInMonths(DateTime(2026, 5, 25), today), 5); // one day short
      expect(ageInMonths(DateTime(2026, 11, 30), today), 0); // future date → 0
    });

    test('addMonths keeps the day, or the last day of a short month', () {
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonths(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
    });
  });

  group('weighing schedule (CHDR)', () {
    test('under 2 years: every month', () {
      final due = weighingDue(dob: DateTime(2026, 4, 1), lastWeighed: DateTime(2026, 10, 24), today: today);
      expect(due!.date, DateTime(2026, 11, 24));
      expect(due.isToday, isTrue);
    });

    test('2 to 5 years: every 3 months', () {
      final dob = DateTime(2023, 6, 1);
      expect(weighingDue(dob: dob, lastWeighed: DateTime(2026, 9, 25), today: today), isNull);
      final late = weighingDue(dob: dob, lastWeighed: DateTime(2026, 8, 20), today: today)!;
      expect(late.overdue, isTrue);
      expect(late.daysLate, 4);
    });

    test('never weighed: due one month after birth', () {
      final due = weighingDue(dob: DateTime(2026, 10, 28), today: today)!;
      expect(due.date, DateTime(2026, 11, 28));
      expect(due.daysLate, -4); // in 4 days
    });

    test('not due if more than a week away', () {
      expect(weighingDue(dob: DateTime(2026, 1, 1), lastWeighed: DateTime(2026, 11, 20), today: today), isNull);
    });

    test('no longer followed from the 5th birthday', () {
      expect(weighingDue(dob: DateTime(2021, 11, 1), today: today), isNull);
    });
  });

  group('pregnancy visits', () {
    test('only pregnant mothers are due', () {
      expect(pregnancyVisitDue(isPregnant: false, nextVisit: today, today: today), isNull);
    });

    test('no visit recorded yet: due today', () {
      expect(pregnancyVisitDue(isPregnant: true, today: today)!.isToday, isTrue);
    });

    test('next visit in the past is late, far future is not shown', () {
      expect(pregnancyVisitDue(isPregnant: true, nextVisit: DateTime(2026, 11, 21), today: today)!.daysLate, 3);
      expect(pregnancyVisitDue(isPregnant: true, nextVisit: DateTime(2026, 12, 15), today: today), isNull);
    });
  });
}
