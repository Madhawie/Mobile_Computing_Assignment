using System.Text.Json.Serialization;

namespace LittleBloom.Domain.Entities;

/// <summary>
/// Fields every synced record has (api.md section 2).
/// The phone creates the record, so the phone also creates the <see cref="Id"/> (UUID).
/// </summary>
public abstract class SyncEntity
{
    /// <summary>UUID made on the phone. Never changes.</summary>
    public Guid Id { get; set; }

    /// <summary>Starts at 1. +1 on every accepted change. S3 compares it to detect conflicts.</summary>
    public int Version { get; set; }

    /// <summary>Time of the last edit, from the phone clock (UTC). Only used to pick the newest value in a conflict.</summary>
    public DateTime UpdatedAt { get; set; }

    /// <summary>Which phone made the last edit.</summary>
    public string DeviceId { get; set; } = string.Empty;

    /// <summary>Soft delete (tombstone). The row stays so the delete can sync to other phones.</summary>
    public bool Deleted { get; set; }

    // ---- Server-only fields. [JsonIgnore] keeps them out of what the phone sends and receives.

    /// <summary>Server change number of the last write. GET /sync/pull?since=N returns rows with ChangeSeq &gt; N.</summary>
    [JsonIgnore]
    public long ChangeSeq { get; set; }

    /// <summary>PHM area the record belongs to (copied from the mother). Used to give each user only their area.</summary>
    [JsonIgnore]
    public string ScopeAreaId { get; set; } = string.Empty;
}
