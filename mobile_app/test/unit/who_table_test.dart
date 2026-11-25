import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/features/phm/growth_record/growth_zone.dart';

/// Checks the bundled WHO table (assets/growth/wfa_lms.json) against values
/// printed in the WHO weight-for-age z-score charts (0–5 years). The charts
/// round weights to 0.1 kg, so the table's weight at each z line must be
/// within 0.05 kg of the printed number.
///
/// Weight at a given z (inverse of the LMS formula): M · (1 + L·S·z)^(1/L).
double weightAt(Lms r, double z) => r.m * math.pow(1 + r.l * r.s * z, 1 / r.l);

void main() {
  final ref = GrowthReference.fromJson(
    jsonDecode(File('assets/growth/wfa_lms.json').readAsStringSync()) as Map<String, dynamic>,
  );

  test('covers every day from birth to 5 years for both sexes', () {
    expect(ref.boys.length, 1827);
    expect(ref.girls.length, 1827);
    expect(ref.source, contains('WHO'));
  });

  test('birth medians match WHO (boys 3.3464 kg, girls 3.2322 kg)', () {
    expect(ref.lms(Sex.boy, 0)!.m, 3.3464);
    expect(ref.lms(Sex.girl, 0)!.m, 3.2322);
  });

  // (sex, age in days, weight kg, z on the WHO chart)
  final chartPoints = [
    (Sex.boy, 0, 2.5, -2.0),
    (Sex.boy, 0, 2.1, -3.0),
    (Sex.boy, 365, 9.6, 0.0),
    (Sex.boy, 365, 7.7, -2.0),
    (Sex.boy, 365, 6.9, -3.0),
    (Sex.girl, 0, 2.4, -2.0),
    (Sex.girl, 365, 8.9, 0.0),
    (Sex.girl, 365, 7.0, -2.0),
    (Sex.girl, 365, 6.3, -3.0),
  ];
  for (final (sex, day, kg, z) in chartPoints) {
    test('${sex.name} day $day: z $z line is $kg kg on the WHO chart', () {
      final r = ref.lms(sex, day)!;
      expect(weightAt(r, z), closeTo(kg, 0.05));
      expect(r.zScore(weightAt(r, z)), closeTo(z, 1e-9)); // formula and inverse agree
    });
  }

  test('zones for a 12-month-old boy: 9.6 green, 7.4 orange, 6.5 red', () {
    final dob = DateTime(2025, 11, 25);
    final oneYear = DateTime(2026, 11, 25);
    GrowthZone zone(double kg) => zoneFor(ref.weightForAgeZ(Sex.boy, dob, oneYear, kg)!);
    expect(zone(9.6), GrowthZone.normal);
    expect(zone(7.4), GrowthZone.moderate);
    expect(zone(6.5), GrowthZone.severe);
  });
}
