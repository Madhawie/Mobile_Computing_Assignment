using LittleBloom.Api.Auth;
using LittleBloom.Application.Common;
using LittleBloom.Application.Sync;
using LittleBloom.Domain.Enums;
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

    public SyncController(IPushService push) => _push = push;

    /// <summary>
    /// Upload outbox changes. Always 200 when the batch was read: each change has its own status,
    /// so one bad record does not block the others.
    /// </summary>
    [HttpPost("push")]
    public async Task<ActionResult<PushResponse>> Push(PushRequest request, CancellationToken ct)
        => Ok(await _push.PushAsync(CurrentUser(), request, ct));

    /// <summary>Reads who is calling from the JWT claims.</summary>
    private SyncUser CurrentUser()
    {
        string? Claim(string name) => User.FindFirst(name)?.Value;

        if (!Guid.TryParse(Claim(ClaimNames.Sub), out var userId)
            || !Enum.TryParse<UserRole>(Claim(ClaimNames.Role), ignoreCase: true, out var role))
            throw new AppException(401, ErrorCodes.Unauthorized, "Token is missing user details.");

        Guid? motherId = Guid.TryParse(Claim(ClaimNames.MotherId), out var m) ? m : null;
        return new SyncUser(userId, role, Claim(ClaimNames.AreaId), Claim(ClaimNames.MohId) ?? string.Empty, motherId);
    }
}
