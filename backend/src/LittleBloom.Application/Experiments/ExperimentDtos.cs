namespace LittleBloom.Application.Experiments;

// Bodies of /api/experiments/* (Development only, admin only). Same purpose as /mock/reset and
// /mock/stats in experiments/scripts/mock_server.py, but for the real .NET server and SQL Server.

/// <summary>"Experiments" section of appsettings. Off by default; on in appsettings.Development.json.</summary>
public class ExperimentOptions
{
    public bool Enabled { get; set; }
}

public record TableCounts(int Mothers, int MaternalVisits, int Children, int GrowthMeasurements, int Vaccinations);

/// <summary>Sync log grouped by endpoint + strategy + network profile.</summary>
public record SyncSummary(
    string Endpoint,
    string? Strategy,
    string? NetworkProfile,
    int Requests,
    int Failed,
    double AvgServerMs,
    int MaxServerMs,
    long RequestBytes,
    long ResponseBytes,
    int RecordsIn,
    int RecordsOut,
    int Duplicates,
    int Merged,
    int Flagged,
    int Rejected);

/// <param name="Records">Rows per synced table (including tombstones).</param>
/// <param name="DeletedRecords">Rows with deleted = true.</param>
/// <param name="ProcessedOperations">Distinct operationIds saved: with retries, still one per change (E4).</param>
public record ExperimentStats(
    TableCounts Records,
    int DeletedRecords,
    int OpenConflicts,
    int ResolvedConflicts,
    int ProcessedOperations,
    int HistoryRows,
    List<SyncSummary> Sync);

public record ResetResponse(int RowsDeleted);
