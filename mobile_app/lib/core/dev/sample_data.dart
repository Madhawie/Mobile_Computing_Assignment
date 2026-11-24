import '../../data/models/models.dart';
import '../../data/repositories/app_repositories.dart';

/// Loads a few made-up mothers and children into the phone so the PHM
/// screens can be tried and demoed. SYNTHETIC DATA ONLY: names and numbers
/// are invented (+94 70 000 01xx is the dev range).
///
/// Records go through the normal repositories, so each one is also queued
/// in the outbox like a real entry; sending them later is a useful sync test.
/// Dates are relative to [today], so something is always due this week.
///
/// The bulk generator for the experiments (50 / 500 / 5000 records) comes on
/// Day 18; this is only for trying the screens.
Future<int> loadSampleData(AppRepositories repos, {required String areaId, required DateTime today}) async {
  DateTime daysAgo(int n) => today.subtract(Duration(days: n));
  DateTime daysAhead(int n) => today.add(Duration(days: n));
  Mother mother(String name, String phone, int age, String address,
          {bool pregnant = false, int? weeks, DateTime? due}) =>
      Mother(
        id: '', version: 0, updatedAt: today, deviceId: '',
        fullName: name, phone: phone, age: age, address: address, areaId: areaId,
        isPregnant: pregnant, gestationWeeks: weeks, dueDate: due,
      );
  var count = 0;

  Future<Mother> addMother(Mother m) async {
    count++;
    return repos.mothers.create(m);
  }

  Future<void> addVisit(Mother m, {required int daysBefore, required int weeks, required double kg,
      required int sys, required int dia, DateTime? next}) async {
    count++;
    await repos.visits.create(MaternalVisit(
      id: '', version: 0, updatedAt: today, deviceId: '', motherId: m.id,
      visitDate: daysAgo(daysBefore), gestationWeeks: weeks, weightKg: kg,
      bpSystolic: sys, bpDiastolic: dia, nextVisit: next,
    ));
  }

  Future<Child> addChild(Mother m, String name, Sex sex, DateTime dob, double birthKg) async {
    count++;
    return repos.children.create(Child(
      id: '', version: 0, updatedAt: today, deviceId: '', motherId: m.id,
      name: name, sex: sex, dateOfBirth: dob, birthWeightKg: birthKg,
    ));
  }

  Future<void> weigh(Child c, DateTime on, double kg, {double? cm}) async {
    count++;
    await repos.growth.create(GrowthMeasurement(
      id: '', version: 0, updatedAt: today, deviceId: '', childId: c.id,
      measuredOn: on, weightKg: kg, heightCm: cm,
    ));
  }

  // Pregnant, visit due in 2 days.
  final nimali = await addMother(mother('Nimali Perera', '+94700000101', 26, '12 Temple Road',
      pregnant: true, weeks: 24, due: daysAhead(112)));
  await addVisit(nimali, daysBefore: 26, weeks: 20, kg: 58.5, sys: 118, dia: 76, next: daysAhead(2));

  // Pregnant, high blood pressure, visit 3 days late.
  final fathima = await addMother(mother('Fathima Rizna', '+94700000102', 31, '4 Mosque Lane',
      pregnant: true, weeks: 33, due: daysAhead(49)));
  await addVisit(fathima, daysBefore: 31, weeks: 29, kg: 66.0, sys: 136, dia: 86, next: daysAgo(17));
  await addVisit(fathima, daysBefore: 17, weeks: 31, kg: 67.2, sys: 144, dia: 92, next: daysAgo(3));

  // Newborn, low birth weight, never weighed after birth.
  final kavitha = await addMother(mother('Kavitha Rajan', '+94700000103', 23, '7 Estate Lines'));
  await addChild(kavitha, 'Baby of Kavitha', Sex.girl, daysAgo(27), 2.3);

  // Baby 7 months, weighed last month: due now.
  final dilani = await addMother(mother('Dilani Silva', '+94700000104', 28, '21 Lake View'));
  final kavin = await addChild(dilani, 'Kavin', Sex.boy, daysAgo(213), 3.1);
  await weigh(kavin, daysAgo(62), 6.9, cm: 64);
  await weigh(kavin, daysAgo(31), 7.4, cm: 66);

  // Child 3 years, weighed 2 months ago: not due yet (every 3 months).
  final sanduni = await addMother(mother('Sanduni Jayasinghe', '+94700000105', 33, '3 School Road'));
  final thenuli = await addChild(sanduni, 'Thenuli', Sex.girl, daysAgo(3 * 365 + 40), 2.9);
  await weigh(thenuli, daysAgo(60), 13.1, cm: 93);

  // Pregnant with no visit recorded yet: due today. Also has a toddler.
  final malathi = await addMother(mother('Malathi Selvaraj', '+94700000106', 27, '9 Hospital Road',
      pregnant: true, weeks: 12, due: daysAhead(196)));
  final ayaan = await addChild(malathi, 'Ayaan', Sex.boy, daysAgo(20 * 30), 3.3);
  await weigh(ayaan, daysAgo(10), 10.2, cm: 80);

  return count;
}
