import 'model_utils.dart';
import 'sync_record.dart';

/// A mother registered by a PHM or the MOH office.
/// Her `phone` is also her sign-in number.
class Mother extends SyncRecord {
  const Mother({
    required super.id,
    required super.version,
    required super.updatedAt,
    required super.deviceId,
    super.deleted,
    super.isDirty,
    required this.fullName,
    required this.phone,
    required this.age,
    required this.address,
    required this.areaId,
    required this.isPregnant,
    this.gestationWeeks,
    this.dueDate,
  });

  static const entityName = 'mother';

  final String fullName;
  final String phone;
  final int age;
  final String address;

  /// PHM area the mother belongs to (decides who may see her record).
  final String areaId;
  final bool isPregnant;
  final int? gestationWeeks;
  final DateTime? dueDate;

  @override
  String get entity => entityName;

  @override
  Map<String, dynamic> dataToJson() => {
        'fullName': fullName,
        'phone': phone,
        'age': age,
        'address': address,
        'areaId': areaId,
        'isPregnant': isPregnant,
        'gestationWeeks': gestationWeeks,
        'dueDate': formatDateOrNull(dueDate),
      };

  @override
  Map<String, dynamic> dataToMap() => {
        'full_name': fullName,
        'phone': phone,
        'age': age,
        'address': address,
        'area_id': areaId,
        'is_pregnant': boolToInt(isPregnant),
        'gestation_weeks': gestationWeeks,
        'due_date': formatDateOrNull(dueDate),
      };

  /// From the API. Records from the server are never dirty.
  factory Mother.fromJson(Map<String, dynamic> j) => Mother(
        id: j['id'] as String,
        version: j['version'] as int,
        updatedAt: parseTimestamp(j['updatedAt']),
        deviceId: j['deviceId'] as String,
        deleted: j['deleted'] as bool? ?? false,
        fullName: j['fullName'] as String,
        phone: j['phone'] as String,
        age: j['age'] as int,
        address: j['address'] as String,
        areaId: j['areaId'] as String,
        isPregnant: j['isPregnant'] as bool,
        gestationWeeks: j['gestationWeeks'] as int?,
        dueDate: parseDateOrNull(j['dueDate']),
      );

  /// From a SQLite row.
  factory Mother.fromMap(Map<String, dynamic> m) => Mother(
        id: m['id'] as String,
        version: m['version'] as int,
        updatedAt: parseTimestamp(m['updated_at']),
        deviceId: m['device_id'] as String,
        deleted: intToBool(m['deleted']),
        isDirty: intToBool(m['is_dirty']),
        fullName: m['full_name'] as String,
        phone: m['phone'] as String,
        age: m['age'] as int,
        address: m['address'] as String,
        areaId: m['area_id'] as String,
        isPregnant: intToBool(m['is_pregnant']),
        gestationWeeks: m['gestation_weeks'] as int?,
        dueDate: parseDateOrNull(m['due_date']),
      );
}
