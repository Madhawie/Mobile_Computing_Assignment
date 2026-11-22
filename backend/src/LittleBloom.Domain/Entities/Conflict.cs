using LittleBloom.Domain.Enums;

namespace LittleBloom.Domain.Entities;

/// <summary>
/// An S3 conflict a person should check: two devices changed the same field,
/// or one deleted a record the other updated. The losing value is kept here and in RecordHistory.
/// </summary>
public class Conflict
{
    public Guid Id { get; set; }
    public string Entity { get; set; } = string.Empty;
    public Guid RecordId { get; set; }
    public string ScopeAreaId { get; set; } = string.Empty;

    /// <summary>"sameField" or "deleteVsUpdate".</summary>
    public string Kind { get; set; } = string.Empty;

    /// <summary>JSON array: [{ "field": "weightKg", "kept": 7.4, "lost": 7.1, "lostDeviceId": "emu-phns-01" }].</summary>
    public string FieldsJson { get; set; } = "[]";

    public ConflictStatus Status { get; set; } = ConflictStatus.Open;
    public DateTime CreatedAt { get; set; }
    public DateTime? ResolvedAt { get; set; }
}
