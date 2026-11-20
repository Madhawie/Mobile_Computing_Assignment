import 'dart:convert';

import 'model_utils.dart';

/// Kind of change in the outbox (`op` in api.md section 4).
enum OutboxOp { upsert, delete }

/// Outbox row state on the phone.
/// `pending` rows are sent at the next sync; `failed` rows were rejected by
/// the server (a 4xx or `rejected`) and are not retried automatically.
enum OutboxStatus { pending, failed }

/// One local change waiting to be pushed.
///
/// Written in the same transaction as the record change (Day 6), so a change
/// can never be saved without also being queued.
class OutboxEntry {
  const OutboxEntry({
    this.id,
    required this.operationId,
    required this.entity,
    required this.op,
    required this.recordId,
    required this.baseVersion,
    required this.changedFields,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.status = OutboxStatus.pending,
    this.lastError,
  });

  /// SQLite autoincrement key; also the send order (oldest first).
  final int? id;

  /// UUID made when the row is written. The server's idempotency key: a
  /// retry sends the same id, so the server answers `duplicate`, not a copy.
  final String operationId;
  final String entity;
  final OutboxOp op;
  final String recordId;

  /// Server version the edit started from (0 for a new record). Used by S3.
  final int baseVersion;

  /// Fields edited since [baseVersion]. Used by S3 for field-level merge.
  final List<String> changedFields;

  /// The full record after the change (its `toJson()`).
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  /// How many times a push with this row has been tried (for E4).
  final int attempts;
  final OutboxStatus status;
  final String? lastError;

  /// One item of `changes` in the push request (api.md section 4).
  Map<String, dynamic> toChangeJson() => {
        'operationId': operationId,
        'entity': entity,
        'op': op.name,
        'recordId': recordId,
        'baseVersion': baseVersion,
        'changedFields': changedFields,
        'data': payload,
      };

  /// SQLite row. Lists and maps are stored as JSON text.
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'operation_id': operationId,
        'entity': entity,
        'op': op.name,
        'record_id': recordId,
        'base_version': baseVersion,
        'changed_fields': jsonEncode(changedFields),
        'payload': jsonEncode(payload),
        'created_at': createdAt.toUtc().toIso8601String(),
        'attempts': attempts,
        'status': status.name,
        'last_error': lastError,
      };

  factory OutboxEntry.fromMap(Map<String, dynamic> m) => OutboxEntry(
        id: m['id'] as int?,
        operationId: m['operation_id'] as String,
        entity: m['entity'] as String,
        op: OutboxOp.values.byName(m['op'] as String),
        recordId: m['record_id'] as String,
        baseVersion: m['base_version'] as int,
        changedFields: (jsonDecode(m['changed_fields'] as String) as List).cast<String>(),
        payload: jsonDecode(m['payload'] as String) as Map<String, dynamic>,
        createdAt: parseTimestamp(m['created_at']),
        attempts: m['attempts'] as int? ?? 0,
        status: OutboxStatus.values.byName(m['status'] as String? ?? 'pending'),
        lastError: m['last_error'] as String?,
      );
}
