namespace LittleBloom.Application.Sync;

/// <summary>Applies a batch of outbox changes from a phone (POST /api/sync/push).</summary>
public interface IPushService
{
    Task<PushResponse> PushAsync(SyncUser user, PushRequest request, CancellationToken ct = default);
}
