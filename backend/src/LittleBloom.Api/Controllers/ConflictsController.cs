using LittleBloom.Api.Auth;
using LittleBloom.Application.Conflicts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LittleBloom.Api.Controllers;

/// <summary>Conflict review for the "Check a record" screen (api.md section 7). Staff only.</summary>
[ApiController]
[Route("api/conflicts")]
[Authorize]
public class ConflictsController : ControllerBase
{
    private readonly IConflictService _conflicts;

    public ConflictsController(IConflictService conflicts) => _conflicts = conflicts;

    /// <summary>Flagged conflicts in the user's scope, newest first, with both values.</summary>
    [HttpGet]
    public async Task<ActionResult<List<ConflictDto>>> List([FromQuery] string? status, CancellationToken ct)
        => Ok(await _conflicts.ListAsync(CurrentUserReader.Read(User), status, ct));

    /// <summary>Decide a conflict: { "keep": "current" } or { "keep": "previous" }.</summary>
    [HttpPost("{id:guid}/resolve")]
    public async Task<ActionResult<ResolveConflictResponse>> Resolve(Guid id, ResolveConflictBody body, CancellationToken ct)
        => Ok(await _conflicts.ResolveAsync(CurrentUserReader.Read(User), id, body, ct));
}
