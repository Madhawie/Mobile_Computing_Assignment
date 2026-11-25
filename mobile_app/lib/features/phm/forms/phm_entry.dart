import '../../../data/models/models.dart';
import '../../../data/repositories/app_repositories.dart';

/// What the PHM forms save. Every method goes through the repositories, so
/// each save is one offline transaction: record + outbox row (Day 6). No
/// method needs a connection.
class PhmEntry {
  PhmEntry(this.repos);

  final AppRepositories repos;

  /// A mother's phone is her sign-in, so two mothers cannot share one.
  Future<bool> phoneTaken(String phoneE164) async =>
      (await repos.mothers.list(where: 'phone = ?', whereArgs: [phoneE164])).isNotEmpty;

  Future<Mother> addMother({
    required String fullName,
    required String phone,
    required int age,
    required String address,
    required String areaId,
    required bool isPregnant,
    int? gestationWeeks,
    DateTime? dueDate,
  }) =>
      repos.mothers.create(Mother(
        id: '', version: 0, updatedAt: DateTime.now(), deviceId: '',
        fullName: fullName.trim(), phone: phone, age: age, address: address.trim(), areaId: areaId,
        isPregnant: isPregnant,
        gestationWeeks: isPregnant ? gestationWeeks : null,
        dueDate: isPregnant ? dueDate : null,
      ));

  Future<Child> addChild({
    required String motherId,
    required String name,
    required Sex sex,
    required DateTime dateOfBirth,
    required double birthWeightKg,
  }) =>
      repos.children.create(Child(
        id: '', version: 0, updatedAt: DateTime.now(), deviceId: '',
        motherId: motherId, name: name.trim(), sex: sex, dateOfBirth: dateOfBirth,
        birthWeightKg: birthWeightKg,
      ));

  Future<GrowthMeasurement> recordGrowth({
    required String childId,
    required DateTime measuredOn,
    required double weightKg,
    double? heightCm,
    String? notes,
  }) =>
      repos.growth.create(GrowthMeasurement(
        id: '', version: 0, updatedAt: DateTime.now(), deviceId: '',
        childId: childId, measuredOn: measuredOn, weightKg: weightKg, heightCm: heightCm,
        notes: _blankToNull(notes),
      ));

  /// Saves the visit and, if the weeks changed, also updates the mother's
  /// "weeks pregnant". That is a second change in the outbox with only
  /// `gestationWeeks` in changedFields, so a clinic edit of another field of
  /// the same mother merges cleanly under S3.
  Future<MaternalVisit> recordVisit({
    required Mother mother,
    required DateTime visitDate,
    required int gestationWeeks,
    required double weightKg,
    required int bpSystolic,
    required int bpDiastolic,
    DateTime? nextVisit,
    String? notes,
  }) async {
    final visit = await repos.visits.create(MaternalVisit(
      id: '', version: 0, updatedAt: DateTime.now(), deviceId: '',
      motherId: mother.id, visitDate: visitDate, gestationWeeks: gestationWeeks, weightKg: weightKg,
      bpSystolic: bpSystolic, bpDiastolic: bpDiastolic, nextVisit: nextVisit, notes: _blankToNull(notes),
    ));
    final current = await repos.mothers.getById(mother.id);
    if (current != null && current.gestationWeeks != gestationWeeks) {
      await repos.mothers.update(Mother(
        id: current.id, version: current.version, updatedAt: current.updatedAt, deviceId: current.deviceId,
        fullName: current.fullName, phone: current.phone, age: current.age, address: current.address,
        areaId: current.areaId, isPregnant: current.isPregnant, gestationWeeks: gestationWeeks,
        dueDate: current.dueDate,
      ));
    }
    return visit;
  }

  Future<Vaccination> recordVaccine({
    required String childId,
    required String vaccine,
    required int dose,
    required DateTime givenOn,
    String? batchNo,
  }) =>
      repos.vaccinations.create(Vaccination(
        id: '', version: 0, updatedAt: DateTime.now(), deviceId: '',
        childId: childId, vaccine: vaccine, dose: dose, givenOn: givenOn, batchNo: _blankToNull(batchNo),
      ));

  static String? _blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}
