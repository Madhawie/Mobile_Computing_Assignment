using System.Text.Json.Nodes;

namespace LittleBloom.Application.Conflicts;

// Bodies of /api/conflicts (api.md section 7).

/// <param name="Fields">[{ field, kept, lost, lostSide, lostDeviceId }] — both values, so a person can choose.</param>
public record ConflictDto(
    Guid Id,
    string Entity,
    Guid RecordId,
    string Kind,
    JsonArray Fields,
    string Status,
    DateTime CreatedAt,
    DateTime? ResolvedAt,
    string? Resolution);

/// <param name="Keep">"current" = leave the record as it is; "previous" = write the lost values back.</param>
public record ResolveConflictBody(string Keep);

public record ResolveConflictResponse(Guid ConflictId, string Resolution, int Version, JsonObject Record);

public static class ConflictKeep
{
    public const string Current = "current";
    public const string Previous = "previous";
}
