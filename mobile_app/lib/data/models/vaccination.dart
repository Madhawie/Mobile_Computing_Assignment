import 'model_utils.dart';
import 'sync_record.dart';

/// A vaccine dose given to a child (e.g. Pentavalent dose 2).
class Vaccination extends SyncRecord {
  const Vaccination({
    required super.id,
    required super.version,
    required super.updatedAt,
    required super.deviceId,
    super.deleted,
    super.isDirty,
    required this.childId,
    required this.vaccine,
    required this.dose,
    required this.givenOn,
    this.batchNo,
  });

  static const entityName = 'vaccination';

  final String childId;
  final String vaccine;
  final int dose;
  final DateTime givenOn;
  final String? batchNo;

  @override
  String get entity => entityName;

  @override
  Map<String, dynamic> dataToJson() => {
        'childId': childId,
        'vaccine': vaccine,
        'dose': dose,
        'givenOn': formatDate(givenOn),
        'batchNo': batchNo,
      };

  @override
  Map<String, dynamic> dataToMap() => {
        'child_id': childId,
        'vaccine': vaccine,
        'dose': dose,
        'given_on': formatDate(givenOn),
        'batch_no': batchNo,
      };

  factory Vaccination.fromJson(Map<String, dynamic> j) => Vaccination(
        id: j['id'] as String,
        version: j['version'] as int,
        updatedAt: parseTimestamp(j['updatedAt']),
        deviceId: j['deviceId'] as String,
        deleted: j['deleted'] as bool? ?? false,
        childId: j['childId'] as String,
        vaccine: j['vaccine'] as String,
        dose: j['dose'] as int,
        givenOn: parseDate(j['givenOn'] as String),
        batchNo: j['batchNo'] as String?,
      );

  factory Vaccination.fromMap(Map<String, dynamic> m) => Vaccination(
        id: m['id'] as String,
        version: m['version'] as int,
        updatedAt: parseTimestamp(m['updated_at']),
        deviceId: m['device_id'] as String,
        deleted: intToBool(m['deleted']),
        isDirty: intToBool(m['is_dirty']),
        childId: m['child_id'] as String,
        vaccine: m['vaccine'] as String,
        dose: m['dose'] as int,
        givenOn: parseDate(m['given_on'] as String),
        batchNo: m['batch_no'] as String?,
      );
}
