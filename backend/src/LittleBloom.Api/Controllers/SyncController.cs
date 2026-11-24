using LittleBloom.Api.Auth;
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
        => Ok(await _push.PushAsync(CurrentUser(), request, ct));

    /// <summary>
    /// Download records changed after "since" (a server change number, not a time).
    /// Repeat with the returned cursor while hasMore is true. Push first, then pull.
    /// </summary>
    [HttpGet("pull")]
    public async Task<ActionResult<PullResponse>> Pull(
        [FromQuery] long since = 0, [FromQuery] int limit = PullLimits.DefaultLimit, CancellationToken ct = default)
        => Ok(await _pull.PullAsync(CurrentUser(), since, limit, ct));

    private SyncUser CurrentUser() => CurrentUserReader.Read(User);
}
