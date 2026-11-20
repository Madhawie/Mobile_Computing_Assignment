import 'model_utils.dart';
import 'sync_record.dart';

/// One weight (and optional height) check of a child.
class GrowthMeasurement extends SyncRecord {
  const GrowthMeasurement({
    required super.id,
    required super.version,
    required super.updatedAt,
    required super.deviceId,
    super.deleted,
    super.isDirty,
    required this.childId,
    required this.measuredOn,
    required this.weightKg,
    this.heightCm,
    this.notes,
  });

  static const entityName = 'growthMeasurement';

  final String childId;
  final DateTime measuredOn;
  final double weightKg;
  final double? heightCm;
  final String? notes;

  @override
  String get entity => entityName;

  @override
  Map<String, dynamic> dataToJson() => {
        'childId': childId,
        'measuredOn': formatDate(measuredOn),
        'weightKg': weightKg,
        'heightCm': heightCm,
        'notes': notes,
      };

  @override
  Map<String, dynamic> dataToMap() => {
        'child_id': childId,
        'measured_on': formatDate(measuredOn),
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'notes': notes,
      };

  factory GrowthMeasurement.fromJson(Map<String, dynamic> j) => GrowthMeasurement(
        id: j['id'] as String,
        version: j['version'] as int,
        updatedAt: parseTimestamp(j['updatedAt']),
        deviceId: j['deviceId'] as String,
        deleted: j['deleted'] as bool? ?? false,
        childId: j['childId'] as String,
        measuredOn: parseDate(j['measuredOn'] as String),
        weightKg: toDouble(j['weightKg']),
        heightCm: toDoubleOrNull(j['heightCm']),
        notes: j['notes'] as String?,
      );

  factory GrowthMeasurement.fromMap(Map<String, dynamic> m) => GrowthMeasurement(
        id: m['id'] as String,
        version: m['version'] as int,
        updatedAt: parseTimestamp(m['updated_at']),
        deviceId: m['device_id'] as String,
        deleted: intToBool(m['deleted']),
        isDirty: intToBool(m['is_dirty']),
        childId: m['child_id'] as String,
        measuredOn: parseDate(m['measured_on'] as String),
        weightKg: toDouble(m['weight_kg']),
        heightCm: toDoubleOrNull(m['height_cm']),
        notes: m['notes'] as String?,
      );
}
