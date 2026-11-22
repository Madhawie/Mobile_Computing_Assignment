namespace LittleBloom.Domain.Entities;

/// <summary>
/// A copy of a record after every accepted change, so older values are never lost.
/// S3 also reads it to find which fields the server changed since the phone's baseVersion.
/// (Answers api.md open question 3: we store the whole row plus the list of changed fields.)
/// </summary>
public class RecordHistory
{
    public long Id { get; set; }
    public string Entity { get; set; } = string.Empty;
    public Guid RecordId { get; set; }

    /// <summary>The version this change produced.</summary>
    public int Version { get; set; }

    /// <summary>Comma-separated camelCase field names changed in this version, e.g. "weightKg,notes". "*" = whole record (create, S1/S2 overwrite).</summary>
    public string ChangedFields { get; set; } = string.Empty;

    /// <summary>The full record after the change, as JSON.</summary>
    public string SnapshotJson { get; set; } = string.Empty;

    public string DeviceId { get; set; } = string.Empty;
    public string Strategy { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
