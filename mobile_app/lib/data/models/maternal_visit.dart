import 'model_utils.dart';
import 'sync_record.dart';

/// One antenatal (pregnancy) visit recorded by the PHM.
class MaternalVisit extends SyncRecord {
  const MaternalVisit({
    required super.id,
    required super.version,
    required super.updatedAt,
    required super.deviceId,
    super.deleted,
    super.isDirty,
    required this.motherId,
    required this.visitDate,
    required this.gestationWeeks,
    required this.weightKg,
    required this.bpSystolic,
    required this.bpDiastolic,
    this.notes,
    this.nextVisit,
  });

  static const entityName = 'maternalVisit';

  final String motherId;
  final DateTime visitDate;
  final int gestationWeeks;
  final double weightKg;

  /// Blood pressure kept as two numbers so it can be checked (e.g. 120 / 80).
  final int bpSystolic;
  final int bpDiastolic;
  final String? notes;
  final DateTime? nextVisit;

  /// 140/90 or higher: the visit screen shows a warning.
  bool get highBloodPressure => bpSystolic >= 140 || bpDiastolic >= 90;

  @override
  String get entity => entityName;

  @override
  Map<String, dynamic> dataToJson() => {
        'motherId': motherId,
        'visitDate': formatDate(visitDate),
        'gestationWeeks': gestationWeeks,
        'weightKg': weightKg,
        'bpSystolic': bpSystolic,
        'bpDiastolic': bpDiastolic,
        'notes': notes,
        'nextVisit': formatDateOrNull(nextVisit),
      };

  @override
  Map<String, dynamic> dataToMap() => {
        'mother_id': motherId,
        'visit_date': formatDate(visitDate),
        'gestation_weeks': gestationWeeks,
        'weight_kg': weightKg,
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'notes': notes,
        'next_visit': formatDateOrNull(nextVisit),
      };

  factory MaternalVisit.fromJson(Map<String, dynamic> j) => MaternalVisit(
        id: j['id'] as String,
        version: j['version'] as int,
        updatedAt: parseTimestamp(j['updatedAt']),
        deviceId: j['deviceId'] as String,
        deleted: j['deleted'] as bool? ?? false,
        motherId: j['motherId'] as String,
        visitDate: parseDate(j['visitDate'] as String),
        gestationWeeks: j['gestationWeeks'] as int,
        weightKg: toDouble(j['weightKg']),
        bpSystolic: j['bpSystolic'] as int,
        bpDiastolic: j['bpDiastolic'] as int,
        notes: j['notes'] as String?,
        nextVisit: parseDateOrNull(j['nextVisit']),
      );

  factory MaternalVisit.fromMap(Map<String, dynamic> m) => MaternalVisit(
        id: m['id'] as String,
        version: m['version'] as int,
        updatedAt: parseTimestamp(m['updated_at']),
        deviceId: m['device_id'] as String,
        deleted: intToBool(m['deleted']),
        isDirty: intToBool(m['is_dirty']),
        motherId: m['mother_id'] as String,
        visitDate: parseDate(m['visit_date'] as String),
        gestationWeeks: m['gestation_weeks'] as int,
        weightKg: toDouble(m['weight_kg']),
        bpSystolic: m['bp_systolic'] as int,
        bpDiastolic: m['bp_diastolic'] as int,
        notes: m['notes'] as String?,
        nextVisit: parseDateOrNull(m['next_visit']),
      );
}
