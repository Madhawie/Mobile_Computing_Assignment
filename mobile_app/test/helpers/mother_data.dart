import 'package:little_bloom/data/models/models.dart';
import 'package:little_bloom/data/repositories/app_repositories.dart';
import 'package:little_bloom/features/parent/vaccines/vaccine_schedule.dart';
import 'package:little_bloom/features/phm/phm_rules.dart';

/// A synthetic family for the mother screens, with dates relative to [today]:
/// 28 weeks pregnant; a girl of 8½ months with every vaccine up to 6 months
/// and three weights; a boy of 3 years whose 18-month vaccines are missing.
class MotherFixture {
  MotherFixture(this.mother, this.girl, this.boy);
  final Mother mother;
  final Child girl;
  final Child boy;
}

Future<MotherFixture> addTestFamily(AppRepositories repos, DateTime today, {String motherId = 'm-1'}) async {
  final d = dateOnly(today);
  final mother = await repos.mothers.create(Mother(
    id: motherId, version: 0, updatedAt: d, deviceId: '', fullName: 'Test Mother', phone: '+94771234567',
    age: 29, address: 'Test Road', areaId: 'glg-east', isPregnant: true, gestationWeeks: 26,
    dueDate: d.add(const Duration(days: 12 * 7)),
  ));
  await repos.visits.create(MaternalVisit(
    id: '', version: 0, updatedAt: d, deviceId: '', motherId: mother.id,
    visitDate: d.subtract(const Duration(days: 14)), gestationWeeks: 26, weightKg: 61.5,
    bpSystolic: 118, bpDiastolic: 76, nextVisit: d.add(const Duration(days: 14)),
  ));

  final girlDob = addMonths(d, -8).subtract(const Duration(days: 15));
  final girl = await repos.children.create(Child(
    id: '', version: 0, updatedAt: d, deviceId: '', motherId: mother.id, name: 'Test Girl', sex: Sex.girl,
    dateOfBirth: girlDob, birthWeightKg: 3.0, chdrNumber: 'TST-0001',
  ));
  for (final step in nationalSchedule.where((s) => s.months <= 6)) {
    for (final dose in step.doses) {
      await repos.vaccinations.create(Vaccination(
        id: '', version: 0, updatedAt: d, deviceId: '', childId: girl.id, vaccine: dose.vaccine, dose: dose.dose,
        givenOn: addMonths(girlDob, step.months),
      ));
    }
  }
  for (final (months, kg) in [(2, 5.0), (5, 6.6), (8, 7.8)]) {
    await repos.growth.create(GrowthMeasurement(
      id: '', version: 0, updatedAt: d, deviceId: '', childId: girl.id,
      measuredOn: addMonths(girlDob, months), weightKg: kg,
    ));
  }

  final boyDob = addMonths(d, -37);
  final boy = await repos.children.create(Child(
    id: '', version: 0, updatedAt: d, deviceId: '', motherId: mother.id, name: 'Test Boy', sex: Sex.boy,
    dateOfBirth: boyDob, birthWeightKg: 3.2,
  ));
  for (final step in nationalSchedule.where((s) => s.months <= 12)) {
    for (final dose in step.doses) {
      await repos.vaccinations.create(Vaccination(
        id: '', version: 0, updatedAt: d, deviceId: '', childId: boy.id, vaccine: dose.vaccine, dose: dose.dose,
        givenOn: addMonths(boyDob, step.months),
      ));
    }
  }
  return MotherFixture(mother, girl, boy);
}
