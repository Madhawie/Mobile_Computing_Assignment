/// Base class for every record that is stored offline and synced.
///
/// Each record has two shapes:
/// * [toJson] – sent to / received from the API (camelCase, see
///   docs/architecture/api.md section 2). `isDirty` is never sent.
/// * [toMap]  – a row in the local SQLite table (snake_case, bools as 0/1).
abstract class SyncRecord {
  const SyncRecord({
    required this.id,
    required this.version,
    required this.updatedAt,
    required this.deviceId,
    this.deleted = false,
    this.isDirty = false,
  });

  /// UUID v4 made on the phone, so the id is the same offline and online.
  final String id;

  /// +1 on every local edit. S3 sends it as `baseVersion` to detect conflicts.
  final int version;

  /// Time of the last edit (device clock, stored in UTC).
  final DateTime updatedAt;

  /// Phone that made the last edit.
  final String deviceId;

  /// Soft delete (tombstone): the record stays so the delete can sync.
  final bool deleted;

  /// Phone only: true while the record has changes not yet confirmed by
  /// the server.
  final bool isDirty;

  /// Value of `entity` in push/pull messages, e.g. `growthMeasurement`.
  String get entity;

  /// The record's own fields for the API (camelCase).
  Map<String, dynamic> dataToJson();

  /// The record's own fields for SQLite (snake_case).
  Map<String, dynamic> dataToMap();

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deviceId': deviceId,
        'deleted': deleted,
        ...dataToJson(),
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'version': version,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'device_id': deviceId,
        'deleted': deleted ? 1 : 0,
        'is_dirty': isDirty ? 1 : 0,
        ...dataToMap(),
      };
}
