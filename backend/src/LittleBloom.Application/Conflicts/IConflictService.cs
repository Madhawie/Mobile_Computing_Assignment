using LittleBloom.Application.Sync;

namespace LittleBloom.Application.Conflicts;

/// <summary>The "Check a record" screen: list flagged S3 conflicts and let a person decide.</summary>
public interface IConflictService
{
    /// <param name="status">"open" (default), "resolved" or "all".</param>
    Task<List<ConflictDto>> ListAsync(SyncUser user, string? status, CancellationToken ct = default);

    Task<ResolveConflictResponse> ResolveAsync(SyncUser user, Guid conflictId, ResolveConflictBody body, CancellationToken ct = default);
}
