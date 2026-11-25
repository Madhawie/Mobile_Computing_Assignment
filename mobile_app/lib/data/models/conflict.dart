import 'dart:convert';

import 'model_utils.dart';

/// One field the server had to decide (api.md §7, backend ConflictDto).
class ConflictField {
  const ConflictField({
    required this.field,
    required this.kept,
    required this.lost,
    required this.lostSide,
    this.lostDeviceId,
  });

  /// API name of the field, e.g. `gestationWeeks`.
  final String field;

  /// Value the record has now (the newer edit).
  final Object? kept;

  /// Older value, saved in history and shown here so a person can choose.
  final Object? lost;

  /// `phone` (the pushing phone's value lost) or `server`.
  final String lostSide;
  final String? lostDeviceId;

  factory ConflictField.fromJson(Map<String, dynamic> j) => ConflictField(
        field: j['field'] as String,
        kept: j['kept'],
        lost: j['lost'],
        lostSide: j['lostSide'] as String? ?? '',
        lostDeviceId: j['lostDeviceId'] as String?,
      );

  Map<String, dynamic> toJson() =>
      {'field': field, 'kept': kept, 'lost': lost, 'lostSide': lostSide, 'lostDeviceId': lostDeviceId};
}

/// An S3 conflict the server flagged: the same field changed on two devices,
/// or a delete met an update. Nothing was lost; a person checks it.
class Conflict {
  const Conflict({
    required this.id,
    required this.entity,
    required this.recordId,
    required this.kind,
    required this.fields,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolution,
  });

  static const open = 'open';
  static const sameField = 'sameField';
  static const deleteVsUpdate = 'deleteVsUpdate';

  final String id;
  final String entity;
  final String recordId;

  /// [sameField] or [deleteVsUpdate].
  final String kind;
  final List<ConflictField> fields;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  /// `current` or `previous` once decided.
  final String? resolution;

  bool get isOpen => status == open;

  factory Conflict.fromJson(Map<String, dynamic> j) => Conflict(
        id: j['id'] as String,
        entity: j['entity'] as String,
        recordId: j['recordId'] as String,
        kind: j['kind'] as String? ?? sameField,
        fields: ((j['fields'] as List?) ?? const [])
            .map((f) => ConflictField.fromJson(f as Map<String, dynamic>))
            .toList(),
        status: j['status'] as String? ?? open,
        createdAt: parseTimestamp(j['createdAt']),
        resolvedAt: j['resolvedAt'] == null ? null : parseTimestamp(j['resolvedAt']),
        resolution: j['resolution'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'entity': entity,
        'record_id': recordId,
        'kind': kind,
        'fields': jsonEncode(fields.map((f) => f.toJson()).toList()),
        'status': status,
        'created_at': createdAt.toUtc().toIso8601String(),
        'resolved_at': resolvedAt?.toUtc().toIso8601String(),
        'resolution': resolution,
      };

  factory Conflict.fromMap(Map<String, dynamic> m) => Conflict(
        id: m['id'] as String,
        entity: m['entity'] as String,
        recordId: m['record_id'] as String,
        kind: m['kind'] as String,
        fields: (jsonDecode(m['fields'] as String) as List)
            .map((f) => ConflictField.fromJson(f as Map<String, dynamic>))
            .toList(),
        status: m['status'] as String,
        createdAt: parseTimestamp(m['created_at']),
        resolvedAt: m['resolved_at'] == null ? null : parseTimestamp(m['resolved_at']),
        resolution: m['resolution'] as String?,
      );
}
