import 'model_utils.dart';
import 'sync_record.dart';

/// Decides the CHDR growth chart: blue book for boys, pink for girls.
enum Sex { boy, girl }

/// A child under 5, linked to its mother.
class Child extends SyncRecord {
  const Child({
    required super.id,
    required super.version,
    required super.updatedAt,
    required super.deviceId,
    super.deleted,
    super.isDirty,
    required this.motherId,
    required this.name,
    required this.sex,
    required this.dateOfBirth,
    required this.birthWeightKg,
    this.bornAt,
    this.chdrNumber,
  });

  static const entityName = 'child';

  final String motherId;
  final String name;
  final Sex sex;
  final DateTime dateOfBirth;
  final double birthWeightKg;
  final String? bornAt;
  final String? chdrNumber;

  /// Under 2.5 kg at birth: the PHM is asked to watch this baby.
  bool get lowBirthWeight => birthWeightKg < 2.5;

  @override
  String get entity => entityName;

  @override
  Map<String, dynamic> dataToJson() => {
        'motherId': motherId,
        'name': name,
        'sex': sex.name,
        'dateOfBirth': formatDate(dateOfBirth),
        'birthWeightKg': birthWeightKg,
        'bornAt': bornAt,
        'chdrNumber': chdrNumber,
      };

  @override
  Map<String, dynamic> dataToMap() => {
        'mother_id': motherId,
        'name': name,
        'sex': sex.name,
        'date_of_birth': formatDate(dateOfBirth),
        'birth_weight_kg': birthWeightKg,
        'born_at': bornAt,
        'chdr_number': chdrNumber,
      };

  factory Child.fromJson(Map<String, dynamic> j) => Child(
        id: j['id'] as String,
        version: j['version'] as int,
        updatedAt: parseTimestamp(j['updatedAt']),
        deviceId: j['deviceId'] as String,
        deleted: j['deleted'] as bool? ?? false,
        motherId: j['motherId'] as String,
        name: j['name'] as String,
        sex: Sex.values.byName(j['sex'] as String),
        dateOfBirth: parseDate(j['dateOfBirth'] as String),
        birthWeightKg: toDouble(j['birthWeightKg']),
        bornAt: j['bornAt'] as String?,
        chdrNumber: j['chdrNumber'] as String?,
      );

  factory Child.fromMap(Map<String, dynamic> m) => Child(
        id: m['id'] as String,
        version: m['version'] as int,
        updatedAt: parseTimestamp(m['updated_at']),
        deviceId: m['device_id'] as String,
        deleted: intToBool(m['deleted']),
        isDirty: intToBool(m['is_dirty']),
        motherId: m['mother_id'] as String,
        name: m['name'] as String,
        sex: Sex.values.byName(m['sex'] as String),
        dateOfBirth: parseDate(m['date_of_birth'] as String),
        birthWeightKg: toDouble(m['birth_weight_kg']),
        bornAt: m['born_at'] as String?,
        chdrNumber: m['chdr_number'] as String?,
      );
}
