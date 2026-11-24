/// Request and response bodies of the API (docs/architecture/api.md).
/// Field names follow the .NET DTOs in backend/.../SyncDtos.cs and AuthDtos.cs.
library;

/// Values of `status` in a push result (api.md section 4).
class ChangeStatus {
  ChangeStatus._();

  static const applied = 'applied';
  static const duplicate = 'duplicate';
  static const conflictMerged = 'conflictMerged';
  static const conflictFlagged = 'conflictFlagged';
  static const rejected = 'rejected';

  /// The server has the change: the phone can remove it from the outbox.
  static bool isConfirmed(String status) => status != rejected;
}

/// What happened to one pushed change.
class ChangeResult {
  const ChangeResult({
    required this.operationId,
    required this.status,
    required this.recordId,
    this.newVersion,
    this.conflictId,
    this.record,
    this.errorCode,
    this.errorField,
  });

  final String operationId;
  final String status;
  final String recordId;
  final int? newVersion;
  final String? conflictId;

  /// Merged record, only for `conflictMerged` / `conflictFlagged`.
  final Map<String, dynamic>? record;
  final String? errorCode;
  final String? errorField;

  factory ChangeResult.fromJson(Map<String, dynamic> j) {
    final error = j['error'] as Map<String, dynamic>?;
    return ChangeResult(
      operationId: j['operationId'] as String,
      status: j['status'] as String,
      recordId: j['recordId'] as String,
      newVersion: j['newVersion'] as int?,
      conflictId: j['conflictId'] as String?,
      record: j['record'] as Map<String, dynamic>?,
      errorCode: error?['code'] as String?,
      errorField: error?['field'] as String?,
    );
  }
}

class PushResponse {
  const PushResponse({required this.results, required this.serverTime, required this.cursor});

  final List<ChangeResult> results;
  final DateTime serverTime;
  final int cursor;

  factory PushResponse.fromJson(Map<String, dynamic> j) => PushResponse(
        results: (j['results'] as List)
            .map((r) => ChangeResult.fromJson(r as Map<String, dynamic>))
            .toList(),
        serverTime: DateTime.parse(j['serverTime'] as String),
        cursor: (j['cursor'] as num).toInt(),
      );
}

/// One record from a pull: its `entity` and the record JSON.
class PulledChange {
  const PulledChange(this.entity, this.record);

  final String entity;
  final Map<String, dynamic> record;
}

class PullResponse {
  const PullResponse({required this.changes, required this.cursor, required this.hasMore});

  final List<PulledChange> changes;

  /// Server change number to send as `since` next time.
  final int cursor;
  final bool hasMore;

  factory PullResponse.fromJson(Map<String, dynamic> j) => PullResponse(
        changes: (j['changes'] as List).map((c) {
          final m = c as Map<String, dynamic>;
          return PulledChange(m['entity'] as String, m['record'] as Map<String, dynamic>);
        }).toList(),
        cursor: (j['cursor'] as num).toInt(),
        hasMore: j['hasMore'] as bool? ?? false,
      );
}

/// The signed-in user from the token response (api.md 9.2).
class ApiUser {
  const ApiUser({
    required this.id,
    required this.role,
    required this.name,
    required this.mohId,
    this.areaId,
    this.motherId,
  });

  final String id;

  /// `mother`, `phm`, `supervisor` or `admin`.
  final String role;
  final String name;
  final String mohId;
  final String? areaId;
  final String? motherId;

  factory ApiUser.fromJson(Map<String, dynamic> j) => ApiUser(
        id: j['id'] as String,
        role: j['role'] as String,
        name: j['name'] as String,
        mohId: j['mohId'] as String? ?? '',
        areaId: j['areaId'] as String?,
        motherId: j['motherId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'name': name,
        'mohId': mohId,
        'areaId': areaId,
        'motherId': motherId,
      };
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;

  /// Seconds until [accessToken] expires.
  final int expiresIn;
  final String refreshToken;
  final ApiUser user;

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        accessToken: j['accessToken'] as String,
        expiresIn: (j['expiresIn'] as num).toInt(),
        refreshToken: j['refreshToken'] as String,
        user: ApiUser.fromJson(j['user'] as Map<String, dynamic>),
      );

  /// Kept in the secure store so the user stays signed in offline.
  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'expiresIn': expiresIn,
        'refreshToken': refreshToken,
        'user': user.toJson(),
      };
}

class OtpRequest {
  const OtpRequest(this.otpRequestId, this.expiresInSeconds);

  final String otpRequestId;
  final int expiresInSeconds;

  factory OtpRequest.fromJson(Map<String, dynamic> j) =>
      OtpRequest(j['otpRequestId'] as String, (j['expiresInSeconds'] as num).toInt());
}
