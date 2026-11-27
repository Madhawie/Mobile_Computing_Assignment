using LittleBloom.Api.Auth;
using LittleBloom.Api.Metrics;
using LittleBloom.Application.Sync;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LittleBloom.Api.Controllers;

/// <summary>Sync endpoints (api.md sections 4 and 5). Signed-in users only.</summary>
[ApiController]
[Route("api/sync")]
[Authorize]
public class SyncController : ControllerBase
{
    private readonly IPushService _push;
    private readonly IPullService _pull;

    public SyncController(IPushService push, IPullService pull)
    {
        _push = push;
        _pull = pull;
    }

    /// <summary>
    /// Upload outbox changes. Always 200 when the batch was read: each change has its own status,
    /// so one bad record does not block the others.
    /// </summary>
    [HttpPost("push")]
    public async Task<ActionResult<PushResponse>> Push(PushRequest request, CancellationToken ct)
    {
        var user = CurrentUser();
        var response = await _push.PushAsync(user, request, ct);

        // Fill the experiment log row the measurement middleware started.
        if (SyncLogItem.Get(HttpContext) is { } log)
        {
            log.UserId = user.UserId;
            log.DeviceId = request.DeviceId;
            log.Strategy = request.Strategy?.Trim().ToUpperInvariant();
            log.RecordsIn = request.Changes?.Count ?? 0;
            log.Applied = response.Results.Count(r => r.Status == ChangeStatus.Applied);
            log.Duplicates = response.Results.Count(r => r.Status == ChangeStatus.Duplicate);
            log.Merged = response.Results.Count(r => r.Status == ChangeStatus.ConflictMerged);
            log.Flagged = response.Results.Count(r => r.Status == ChangeStatus.ConflictFlagged);
            log.Rejected = response.Results.Count(r => r.Status == ChangeStatus.Rejected);
        }

        return Ok(response);
    }

    /// <summary>
    /// Download records changed after "since" (a server change number, not a time).
    /// Repeat with the returned cursor while hasMore is true. Push first, then pull.
    /// </summary>
    [HttpGet("pull")]
    public async Task<ActionResult<PullResponse>> Pull(
        [FromQuery] long since = 0, [FromQuery] int limit = PullLimits.DefaultLimit, CancellationToken ct = default)
    {
        var user = CurrentUser();
        var response = await _pull.PullAsync(user, since, limit, ct);

        if (SyncLogItem.Get(HttpContext) is { } log)
        {
            log.UserId = user.UserId;
            log.RecordsOut = response.Changes.Count;
        }

        return Ok(response);
    }

    private SyncUser CurrentUser() => CurrentUserReader.Read(User);
}
