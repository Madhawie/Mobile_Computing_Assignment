import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bloom/core/storage/app_database.dart';
import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:little_bloom/features/parent/advice/advice_content.dart';
import 'package:little_bloom/features/parent/home/mother_view_model.dart';
import 'package:little_bloom/features/parent/vaccines/vaccine_schedule.dart';
import 'package:little_bloom/features/phm/growth_record/growth_zone.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/mother_data.dart';

Vaccination _given(String vaccine, int dose, DateTime on, {bool deleted = false}) => Vaccination(
      id: '$vaccine$dose', version: 1, updatedAt: on, deviceId: 'x', deleted: deleted,
      childId: 'c', vaccine: vaccine, dose: dose, givenOn: on,
    );

void main() {
  group('vaccine card', () {
    final dob = DateTime(2026, 2, 19);
    final upTo6Months = [
      for (final s in nationalSchedule.where((s) => s.months <= 6))
        for (final d in s.doses) _given(d.vaccine, d.dose, DateTime(2026, 2 + s.months, 20)),
    ];

    test('dates come from the date of birth; 4 of 9 given; MMR 1 is next', () {
      final card = VaccineCard.build(dob, upTo6Months, DateTime(2026, 11, 10));
      expect(card.steps.map((s) => s.dueOn), [
        DateTime(2026, 2, 19), DateTime(2026, 4, 19), DateTime(2026, 6, 19), DateTime(2026, 8, 19),
        DateTime(2026, 11, 19), DateTime(2027, 2, 19), DateTime(2027, 8, 19), DateTime(2029, 2, 19),
        DateTime(2031, 2, 19),
      ]);
      expect((card.givenCount, card.onTrack), (4, true));
      expect(card.next!.missing.single.label, 'MMR 1');
      expect(card.steps.map((s) => s.status.name).skip(4),
          ['due', 'upcoming', 'upcoming', 'upcoming', 'upcoming']);
    });

    test('a dose missing from a past visit makes that visit late and next', () {
      final withoutFipv2 = upTo6Months.where((v) => !(v.vaccine == 'fIPV' && v.dose == 2)).toList();
      final card = VaccineCard.build(dob, withoutFipv2, DateTime(2026, 11, 10));
      expect(card.onTrack, isFalse);
      expect(card.next!.step.months, 4);
      expect(card.next!.missing.map((d) => d.label), ['fIPV 2']);
      expect(card.next!.status, StepStatus.late);
    });

    test('the day after MMR 1 was due it is late', () {
      final card = VaccineCard.build(dob, upTo6Months, DateTime(2026, 11, 20));
      expect(card.next!.status, StepStatus.late);
    });

    test('a deleted vaccination does not count', () {
      final card = VaccineCard.build(dob, [_given('BCG', 1, dob, deleted: true)], dob);
      expect(card.steps.first.status, StepStatus.due);
    });

    test('born on the 31st: 2 months later is the end of February', () {
      final card = VaccineCard.build(DateTime(2025, 12, 31), const [], DateTime(2025, 12, 31));
      expect(card.steps[1].dueOn, DateTime(2026, 2, 28));
    });
  });

  test('LMS turned round gives the weight of a z-score (chart bands)', () {
    const boysAtBirth = Lms(0.3487, 3.3464, 0.14602); // WHO weianthro, boys, day 0
    expect(boysAtBirth.valueAt(0), closeTo(3.3464, 1e-9)); // z 0 = the median
    for (final z in [-3.0, -2.0, 2.0]) {
      expect(boysAtBirth.zScore(boysAtBirth.valueAt(z)), closeTo(z, 1e-9));
    }
    expect(boysAtBirth.valueAt(-2), closeTo(2.5, 0.05)); // WHO table: 2.5 kg at −2 SD
    const lZero = Lms(0, 10, 0.1);
    expect(lZero.zScore(lZero.valueAt(-2)), closeTo(-2, 1e-9));
  });

  group('advice', () {
    final advice = AdviceContent.fromJson(
        jsonDecode(File('assets/advice/advice.json').readAsStringSync()) as Map<String, dynamic>);

    test('each age goes to the right band; after 5 years the last band', () {
      expect([for (final m in [0, 5, 6, 11, 12, 23, 24, 59, 70]) advice.groupFor(m).id],
          ['0-6m', '0-6m', '6-12m', '6-12m', '1-2y', '1-2y', '2-5y', '2-5y', '2-5y']);
    });

    test('every band has feeding, play and safety; danger signs say 1990', () {
      for (final g in advice.groups) {
        expect(g.cards.map((c) => c.kind), AdviceKind.values, reason: g.id);
      }
      expect(advice.dangerSigns.body.of('en'), contains('1990'));
      expect(advice.pregnancyDangerSigns.body.of('en'), contains('1990'));
    });

    test('Sinhala not written yet: falls back to English', () {
      expect(advice.groups.first.cards.first.title.of('si'), advice.groups.first.cards.first.title.of('en'));
    });
  });

  group('MotherViewModel', () {
    late AppDatabase store;
    late AppRepositories repos;
    final today = DateTime(2026, 11, 25);

    setUp(() async {
      sqfliteFfiInit();
      store = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
      repos = AppRepositories(store);
    });
    tearDown(() => store.close());

    test('her own children, oldest first, with cards and weights', () async {
      final f = await addTestFamily(repos, today);
      final vm = MotherViewModel(repos, motherId: f.mother.id, clock: () => today);
      await vm.load();

      expect(vm.children.map((c) => c.child.name), ['Test Boy', 'Test Girl']);
      final girl = vm.children.last;
      expect((girl.card.givenCount, girl.growth.length, girl.latest!.weightKg), (4, 3, 7.8));
      expect(vm.children.first.card.onTrack, isFalse); // the boy's 18-month vaccines are late
      expect(vm.weeksPregnantNow, 28);
      expect(vm.nextAntenatal!.date, DateTime(2026, 12, 9));
    });

    test('coming up is sorted by date; the chosen child stays chosen', () async {
      final f = await addTestFamily(repos, today);
      final vm = MotherViewModel(repos, motherId: f.mother.id, clock: () => today);
      await vm.load();
      final dates = vm.comingUp.map((u) => u.date).toList();
      expect(dates, [...dates]..sort());
      expect(vm.comingUp.map((u) => u.kind), containsAll(UpcomingKind.values));

      expect(vm.selected!.child.name, 'Test Boy');
      vm.select(f.girl.id);
      await vm.load();
      expect(vm.selected!.child.name, 'Test Girl');
    });

    test('another mother\'s children are not shown', () async {
      await addTestFamily(repos, today, motherId: 'other');
      final vm = MotherViewModel(repos, motherId: 'm-1', clock: () => today);
      await vm.load();
      expect(vm.mother, isNull);
      expect(vm.children, isEmpty);
    });

    test('account not linked to a mother record: nothing loaded, no error', () async {
      final vm = MotherViewModel(repos, motherId: null, clock: () => today);
      await vm.load();
      expect((vm.loading, vm.mother), (false, null));
    });
  });
}
