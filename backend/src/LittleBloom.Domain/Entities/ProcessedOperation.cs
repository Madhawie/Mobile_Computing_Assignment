namespace LittleBloom.Domain.Entities;

/// <summary>
/// One row per outbox change the server has already handled. The key is the phone's operationId.
/// If the connection drops after the server saved a change but before the phone got the answer,
/// the phone sends the same change again. The server finds the operationId here and answers
/// "duplicate" instead of saving it twice. This is what makes push idempotent (experiment E4).
/// </summary>
public class ProcessedOperation
{
    public Guid OperationId { get; set; }
    public string Entity { get; set; } = string.Empty;
    public Guid RecordId { get; set; }
    public string DeviceId { get; set; } = string.Empty;

    /// <summary>Result the first time: applied, conflictMerged, conflictFlagged.</summary>
    public string Status { get; set; } = string.Empty;

    public int? NewVersion { get; set; }
    public Guid? ConflictId { get; set; }
    public DateTime ProcessedAt { get; set; }
}
