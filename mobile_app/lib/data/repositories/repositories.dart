/// One repository per record type, with the queries the screens need.
/// All writes go through [RecordRepository] (record + outbox in one
/// transaction).
library;

import '../../core/storage/schema.dart';
import '../models/models.dart';
import 'record_repository.dart';

export 'outbox_repository.dart';
export 'record_repository.dart';

class MotherRepository extends RecordRepository<Mother> {
  MotherRepository(super.store, {super.clock, super.uuid})
      : super(
            table: Tables.mothers,
            entity: Mother.entityName,
            fromMap: Mother.fromMap);

  /// Area register, A–Z.
  Future<List<Mother>> inArea(String areaId) =>
      list(where: 'area_id = ?', whereArgs: [areaId], orderBy: 'full_name COLLATE NOCASE');

  /// Search by part of the name or phone number.
  Future<List<Mother>> search(String text) {
    final like = '%${text.trim()}%';
    return list(
      where: 'full_name LIKE ? OR phone LIKE ?',
      whereArgs: [like, like],
      orderBy: 'full_name COLLATE NOCASE',
    );
  }
}

class MaternalVisitRepository extends RecordRepository<MaternalVisit> {
  MaternalVisitRepository(super.store, {super.clock, super.uuid})
      : super(
            table: Tables.maternalVisits,
            entity: MaternalVisit.entityName,
            fromMap: MaternalVisit.fromMap);

  /// Newest visit first.
  Future<List<MaternalVisit>> forMother(String motherId) =>
      list(where: 'mother_id = ?', whereArgs: [motherId], orderBy: 'visit_date DESC');
}

class ChildRepository extends RecordRepository<Child> {
  ChildRepository(super.store, {super.clock, super.uuid})
      : super(
            table: Tables.children,
            entity: Child.entityName,
            fromMap: Child.fromMap);

  /// Oldest child first.
  Future<List<Child>> forMother(String motherId) =>
      list(where: 'mother_id = ?', whereArgs: [motherId], orderBy: 'date_of_birth');
}

class GrowthRepository extends RecordRepository<GrowthMeasurement> {
  GrowthRepository(super.store, {super.clock, super.uuid})
      : super(
            table: Tables.growthMeasurements,
            entity: GrowthMeasurement.entityName,
            fromMap: GrowthMeasurement.fromMap);

  /// Oldest first, the order of points on the growth chart.
  Future<List<GrowthMeasurement>> forChild(String childId) =>
      list(where: 'child_id = ?', whereArgs: [childId], orderBy: 'measured_on');
}

class VaccinationRepository extends RecordRepository<Vaccination> {
  VaccinationRepository(super.store, {super.clock, super.uuid})
      : super(
            table: Tables.vaccinations,
            entity: Vaccination.entityName,
            fromMap: Vaccination.fromMap);

  Future<List<Vaccination>> forChild(String childId) =>
      list(where: 'child_id = ?', whereArgs: [childId], orderBy: 'given_on');
}
