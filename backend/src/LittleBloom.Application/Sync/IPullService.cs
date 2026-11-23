namespace LittleBloom.Application.Sync;

/// <summary>Returns records changed after a cursor, only those the user may see (GET /api/sync/pull).</summary>
public interface IPullService
{
    Task<PullResponse> PullAsync(SyncUser user, long since, int limit, CancellationToken ct = default);
}
