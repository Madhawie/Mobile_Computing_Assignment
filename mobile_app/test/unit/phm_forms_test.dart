import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/storage/app_database.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:little_bloom/features/phm/forms/form_rules.dart';
import 'package:little_bloom/features/phm/forms/phm_entry.dart';
import 'package:little_bloom/features/phm/growth_record/growth_zone.dart';
import 'package:little_bloom/l10n/app_localizations_en.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// MADE-UP reference for tests only (NOT WHO numbers): every day has
/// L = 0, M = 3.3 kg, S = 0.1, so z = ln(weight / 3.3) / 0.1.
GrowthReference fakeReference() {
  final rows = List.filled(1857, const Lms(0, 3.3, 0.1));
  return GrowthReference(boys: rows, girls: rows, source: 'test only');
}

double weightAtZ(double z) => 3.3 * math.exp(z * 0.1);

class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => throw StateError('no asset $key');
}

void main() {
  final rules = FormRules(AppLocalizationsEn());

  group('FormRules', () {
    test('numbers: comma or point, range, whole numbers', () {
      expect(FormRules.parseNumber(' 7,4 '), 7.4);
      expect(rules.number('7.4', 0.5, 40), isNull);
      expect(rules.number('74', 0.5, 40), 'Enter a number from 0.5 to 40'); // typing slip
      expect(rules.number('', 30, 130, optional: true), isNull);
      expect(rules.number('', 30, 130), 'Please fill this in');
      expect(rules.wholeNumber('24.5', 14, 55), isNotNull);
    });

    test('blood pressure: top must be higher than bottom', () {
      expect(rules.bloodPressure('120', '80'), isNull);
      expect(rules.bloodPressure('80', '120'), isNotNull);
    });

    test('dates: no future dates', () {
      final today = DateTime(2026, 11, 25);
      expect(rules.notFuture(DateTime(2026, 11, 25, 23), today), isNull);
      expect(rules.notFuture(DateTime(2026, 11, 26), today), 'The date cannot be in the future.');
    });

    test('due date from weeks; next visit spacing 4 / 2 / 1 weeks', () {
      final d = DateTime(2026, 11, 25);
      expect(FormRules.dueDateFromWeeks(20, d), DateTime(2027, 4, 14));
      expect(FormRules.suggestedNextVisit(20, d), DateTime(2026, 12, 23));
      expect(FormRules.suggestedNextVisit(30, d), DateTime(2026, 12, 9));
      expect(FormRules.suggestedNextVisit(37, d), DateTime(2026, 12, 2));
    });
  });

  group('growth zones', () {
    test('LMS z-score formula, with L = 0 and L ≠ 0', () {
      expect(const Lms(0, 3.3, 0.1).zScore(3.3), closeTo(0, 1e-9));
      // L = 1: z = (x/M − 1) / S
      expect(const Lms(1, 10, 0.1).zScore(11), closeTo(1, 1e-9));
    });

    test('zone boundaries −3, −2, +2', () {
      expect(zoneFor(-3.5), GrowthZone.severe);
      expect(zoneFor(-2.5), GrowthZone.moderate);
      expect(zoneFor(-2), GrowthZone.normal);
      expect(zoneFor(2), GrowthZone.normal);
      expect(zoneFor(2.5), GrowthZone.overweight);
    });

    test('uses the row for the age in days; outside the table gives null', () {
      final ref = fakeReference();
      final dob = DateTime(2026, 1, 1);
      expect(ref.weightForAgeZ(Sex.girl, dob, DateTime(2026, 6, 1), weightAtZ(-2.5)), closeTo(-2.5, 1e-9));
      expect(ref.weightForAgeZ(Sex.boy, dob, DateTime(2031, 6, 1), 15), isNull); // over 5 years
    });

    test('reads the JSON format made by tool/make_wfa_table.py', () {
      final ref = GrowthReference.fromJson({
        'source': 'test',
        'boy': [[0.3, 3.3, 0.14]],
        'girl': [[0.4, 3.2, 0.14]],
      });
      expect(ref.lms(Sex.girl, 0)!.m, 3.2);
      expect(ref.lms(Sex.boy, 1), isNull);
    });

    test('no table in the app yet → null, the form shows "not available"', () async {
      expect(await GrowthReference.load(_EmptyBundle()), isNull);
    });
  });

  group('PhmEntry (saves offline)', () {
    sqfliteFfiInit();
    late AppDatabase store;
    late AppRepositories repos;
    late PhmEntry entry;

    setUp(() async {
      store = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
      repos = AppRepositories(store);
      entry = PhmEntry(repos);
    });
    tearDown(() => store.close());

    Future<Mother> addPregnant({int weeks = 20}) => entry.addMother(
          fullName: ' Test Mother ', phone: '+94700000150', age: 25, address: 'Test Road',
          areaId: 'glg-east', isPregnant: true, gestationWeeks: weeks, dueDate: DateTime(2027, 4, 1),
        );

    test('add mother: trimmed, queued once; the phone is then taken', () async {
      final m = await addPregnant();
      expect(m.fullName, 'Test Mother');
      expect(await repos.outbox.pendingCount(), 1);
      expect(await entry.phoneTaken('+94700000150'), isTrue);
      expect(await entry.phoneTaken('+94700000151'), isFalse);
    });

    test('not pregnant: weeks and due date are not kept', () async {
      final m = await entry.addMother(
        fullName: 'B', phone: '+94700000152', age: 30, address: 'x', areaId: 'a',
        isPregnant: false, gestationWeeks: 12, dueDate: DateTime(2027),
      );
      expect((m.gestationWeeks, m.dueDate), (null, null));
    });

    test('visit with new weeks also queues a gestationWeeks-only change for the mother', () async {
      final m = await addPregnant(weeks: 20);
      await entry.recordVisit(
        mother: m, visitDate: DateTime(2026, 11, 25), gestationWeeks: 22, weightKg: 60,
        bpSystolic: 120, bpDiastolic: 80, nextVisit: DateTime(2026, 12, 23), notes: '  ',
      );
      final queued = await repos.outbox.pending();
      expect(queued.map((e) => e.entity), ['mother', 'maternalVisit', 'mother']);
      expect(queued.last.changedFields, ['gestationWeeks']);
      expect((await repos.mothers.getById(m.id))!.gestationWeeks, 22);
      expect((await repos.visits.forMother(m.id)).single.notes, isNull); // blank → null
    });

    test('visit with the same weeks does not touch the mother', () async {
      final m = await addPregnant(weeks: 20);
      await entry.recordVisit(
        mother: m, visitDate: DateTime(2026, 11, 25), gestationWeeks: 20, weightKg: 60,
        bpSystolic: 120, bpDiastolic: 80,
      );
      expect((await repos.outbox.pending()).map((e) => e.entity), ['mother', 'maternalVisit']);
    });

    test('child, growth and vaccine are each one queued change', () async {
      final m = await addPregnant();
      final c = await entry.addChild(
          motherId: m.id, name: 'Test Baby', sex: Sex.girl, dateOfBirth: DateTime(2026, 10, 1), birthWeightKg: 2.4);
      expect(c.lowBirthWeight, isTrue);
      await entry.recordGrowth(childId: c.id, measuredOn: DateTime(2026, 11, 1), weightKg: 3.6, heightCm: 52);
      await entry.recordVaccine(childId: c.id, vaccine: 'BCG', dose: 1, givenOn: DateTime(2026, 10, 1));
      expect((await repos.outbox.pending()).map((e) => e.entity),
          ['mother', 'child', 'growthMeasurement', 'vaccination']);
    });
  });
}
