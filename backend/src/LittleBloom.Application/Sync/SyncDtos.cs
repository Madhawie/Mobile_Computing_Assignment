using System.Text.Json.Nodes;

namespace LittleBloom.Application.Sync;

// Bodies of POST /api/sync/push (api.md section 4). Serialised in camelCase.

public record PushRequest(string DeviceId, string Strategy, Guid? BatchId, List<PushChange> Changes);

/// <summary>One outbox entry from the phone.</summary>
/// <param name="OperationId">Idempotency key: the same change retried keeps the same id.</param>
/// <param name="Op">"upsert" or "delete".</param>
/// <param name="BaseVersion">Server version the edit started from (0 = new). S3 only.</param>
/// <param name="ChangedFields">Fields edited since BaseVersion. S3 only.</param>
/// <param name="Data">The full record after the edit.</param>
public record PushChange(
    Guid OperationId,
    string Entity,
    string Op,
    Guid RecordId,
    int BaseVersion,
    List<string>? ChangedFields,
    JsonObject? Data);

public record PushResponse(List<ChangeResult> Results, DateTime ServerTime, long Cursor);

/// <summary>What happened to one change. Null fields are left out of the JSON.</summary>
public record ChangeResult(
    Guid OperationId,
    string Status,
    Guid RecordId,
    int? NewVersion = null,
    Guid? ConflictId = null,
    JsonObject? Record = null,
    ChangeError? Error = null);

public record ChangeError(string Code, string? Field = null);

/// <summary>Values of ChangeResult.Status. The phone decides what to do from these (api.md section 4).</summary>
public static class ChangeStatus
{
    public const string Applied = "applied";
    public const string Duplicate = "duplicate";
    public const string ConflictMerged = "conflictMerged";
    public const string ConflictFlagged = "conflictFlagged";
    public const string Rejected = "rejected";
}

public static class SyncLimits
{
    /// <summary>Most changes in one push (api.md section 4). More → 413 BATCH_TOO_LARGE.</summary>
    public const int MaxPushChanges = 200;
}
