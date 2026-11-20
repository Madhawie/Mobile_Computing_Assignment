import 'model_utils.dart';

/// One sync run, written after every sync. This table is the raw data for
/// the experiments (E1–E6) and is exported as CSV.
class SyncLog {
  const SyncLog({
    this.id,
    required this.strategy,
    required this.startedAt,
    required this.durationMs,
    required this.recordCount,
    required this.changedCount,
    required this.bytesSent,
    required this.bytesReceived,
    required this.networkProfile,
    required this.success,
    this.conflicts = 0,
    this.duplicates = 0,
    this.retries = 0,
    this.errorCode,
    this.runLabel,
  });

  final int? id;

  /// `S1`, `S2` or `S3`.
  final String strategy;
  final DateTime startedAt;
  final int durationMs;

  /// Records the phone holds in the synced scope.
  final int recordCount;

  /// Records actually sent (all of them for S1, only changed ones for S2/S3).
  final int changedCount;
  final int bytesSent;
  final int bytesReceived;

  /// `4G`, `3G`, `2G` or `none` (Toxiproxy profile in use).
  final String networkProfile;
  final bool success;
  final int conflicts;
  final int duplicates;
  final int retries;
  final String? errorCode;

  /// Experiment run name, e.g. `E1-500-run3`. Null for normal use.
  final String? runLabel;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'strategy': strategy,
        'started_at': startedAt.toUtc().toIso8601String(),
        'duration_ms': durationMs,
        'record_count': recordCount,
        'changed_count': changedCount,
        'bytes_sent': bytesSent,
        'bytes_received': bytesReceived,
        'network_profile': networkProfile,
        'success': boolToInt(success),
        'conflicts': conflicts,
        'duplicates': duplicates,
        'retries': retries,
        'error_code': errorCode,
        'run_label': runLabel,
      };

  factory SyncLog.fromMap(Map<String, dynamic> m) => SyncLog(
        id: m['id'] as int?,
        strategy: m['strategy'] as String,
        startedAt: parseTimestamp(m['started_at']),
        durationMs: m['duration_ms'] as int,
        recordCount: m['record_count'] as int,
        changedCount: m['changed_count'] as int,
        bytesSent: m['bytes_sent'] as int,
        bytesReceived: m['bytes_received'] as int,
        networkProfile: m['network_profile'] as String,
        success: intToBool(m['success']),
        conflicts: m['conflicts'] as int? ?? 0,
        duplicates: m['duplicates'] as int? ?? 0,
        retries: m['retries'] as int? ?? 0,
        errorCode: m['error_code'] as String?,
        runLabel: m['run_label'] as String?,
      );

  /// CSV columns, in the same order as [toCsvRow]. Read by the pandas scripts.
  static const csvHeader = [
    'strategy', 'started_at', 'duration_ms', 'record_count', 'changed_count',
    'bytes_sent', 'bytes_received', 'network_profile', 'success',
    'conflicts', 'duplicates', 'retries', 'error_code', 'run_label',
  ];

  List<Object?> toCsvRow() => [
        strategy, startedAt.toUtc().toIso8601String(), durationMs, recordCount,
        changedCount, bytesSent, bytesReceived, networkProfile, boolToInt(success),
        conflicts, duplicates, retries, errorCode ?? '', runLabel ?? '',
      ];
}
