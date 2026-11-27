using System.Text;
using LittleBloom.Application.Common;
using LittleBloom.Application.Experiments;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LittleBloom.Api.Controllers;

/// <summary>
/// Experiment helpers (api.md section 12). Only when Experiments:Enabled is true
/// (appsettings.Development.json) and only for the admin; otherwise 404, so they never exist in production.
/// </summary>
[ApiController]
[Route("api/experiments")]
[Authorize(Roles = "admin")]
public class ExperimentsController : ControllerBase
{
    private readonly IExperimentService _experiments;
    private readonly ExperimentOptions _options;

    public ExperimentsController(IExperimentService experiments, ExperimentOptions options)
    {
        _experiments = experiments;
        _options = options;
    }

    /// <summary>Empty the server before a run. ?keepSyncLog=true keeps the measurements of earlier runs.</summary>
    [HttpPost("reset")]
    public async Task<ActionResult<ResetResponse>> Reset([FromQuery] bool keepSyncLog = false, CancellationToken ct = default)
    {
        EnsureEnabled();
        return Ok(await _experiments.ResetAsync(keepSyncLog, ct));
    }

    /// <summary>Record counts, conflicts, processed operations and the sync log summary.</summary>
    [HttpGet("stats")]
    public async Task<ActionResult<ExperimentStats>> Stats(CancellationToken ct)
    {
        EnsureEnabled();
        return Ok(await _experiments.GetStatsAsync(ct));
    }

    /// <summary>Server sync log as CSV, e.g. saved to experiments/data/ and read with pandas.</summary>
    [HttpGet("sync-log.csv")]
    public async Task<IActionResult> SyncLogCsv([FromQuery] DateTime? since, CancellationToken ct)
    {
        EnsureEnabled();
        var csv = await _experiments.ExportSyncLogCsvAsync(since, ct);
        return File(Encoding.UTF8.GetBytes(csv), "text/csv", "sync_log_server.csv");
    }

    private void EnsureEnabled()
    {
        if (!_options.Enabled)
            throw new AppException(404, ErrorCodes.NotFound, "Experiments are switched off on this server.");
    }
}
