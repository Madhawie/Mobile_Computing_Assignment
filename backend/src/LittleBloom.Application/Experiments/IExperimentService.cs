namespace LittleBloom.Application.Experiments;

/// <summary>Helpers for running the experiments against the real server (not used by the app).</summary>
public interface IExperimentService
{
    /// <summary>Empties synced records, history, conflicts, processed operations and mother accounts. Staff stay.</summary>
    Task<ResetResponse> ResetAsync(bool keepSyncLog, CancellationToken ct = default);

    Task<ExperimentStats> GetStatsAsync(CancellationToken ct = default);

    /// <summary>The server sync log as CSV (one row per push or pull), for pandas.</summary>
    Task<string> ExportSyncLogCsvAsync(DateTime? since, CancellationToken ct = default);

    /// <summary>Inserts synthetic records directly on the server (E1 starting data). Phones then pull them.</summary>
    Task<SeedResponse> SeedAsync(SeedRequest request, CancellationToken ct = default);
}
