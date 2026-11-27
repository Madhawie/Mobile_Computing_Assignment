using System.Globalization;
using System.Text;
using LittleBloom.Application.Experiments;
using LittleBloom.Domain.Enums;
using LittleBloom.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LittleBloom.Infrastructure.Experiments;

/// <summary>
/// Reset, stats and CSV export for experiment runs. Each run starts from an empty server
/// (reset), the phones sync, then stats/CSV give the server-side numbers for the report.
/// </summary>
public class ExperimentService : IExperimentService
{
    private readonly AppDbContext _db;

    public ExperimentService(AppDbContext db) => _db = db;

    public async Task<ResetResponse> ResetAsync(bool keepSyncLog, CancellationToken ct = default)
    {
        // ExecuteDelete runs one DELETE per table in the database, without loading rows.
        var deleted = 0;
        deleted += await _db.Vaccinations.ExecuteDeleteAsync(ct);
        deleted += await _db.GrowthMeasurements.ExecuteDeleteAsync(ct);
        deleted += await _db.MaternalVisits.ExecuteDeleteAsync(ct);
        deleted += await _db.Children.ExecuteDeleteAsync(ct);
        deleted += await _db.Mothers.ExecuteDeleteAsync(ct);
        deleted += await _db.ProcessedOperations.ExecuteDeleteAsync(ct);
        deleted += await _db.RecordHistory.ExecuteDeleteAsync(ct);
        deleted += await _db.Conflicts.ExecuteDeleteAsync(ct);
        deleted += await _db.Users.Where(u => u.Role == UserRole.Mother).ExecuteDeleteAsync(ct);
        if (!keepSyncLog) deleted += await _db.SyncLogs.ExecuteDeleteAsync(ct);

        // The ChangeSeq sequence is NOT reset: cursors only ever go up.
        // Phones must clear their local database too before the next run.
        return new ResetResponse(deleted);
    }

    public async Task<ExperimentStats> GetStatsAsync(CancellationToken ct = default)
    {
        var records = new TableCounts(
            await _db.Mothers.CountAsync(ct),
            await _db.MaternalVisits.CountAsync(ct),
            await _db.Children.CountAsync(ct),
            await _db.GrowthMeasurements.CountAsync(ct),
            await _db.Vaccinations.CountAsync(ct));

        var deleted = await _db.Mothers.CountAsync(r => r.Deleted, ct)
                      + await _db.MaternalVisits.CountAsync(r => r.Deleted, ct)
                      + await _db.Children.CountAsync(r => r.Deleted, ct)
                      + await _db.GrowthMeasurements.CountAsync(r => r.Deleted, ct)
                      + await _db.Vaccinations.CountAsync(r => r.Deleted, ct);

        var sync = await _db.SyncLogs.AsNoTracking()
            .GroupBy(l => new { l.Endpoint, l.Strategy, l.NetworkProfile })
            .Select(g => new SyncSummary(
                g.Key.Endpoint,
                g.Key.Strategy,
                g.Key.NetworkProfile,
                g.Count(),
                g.Count(x => !x.Success),
                g.Average(x => (double)x.DurationMs),
                g.Max(x => x.DurationMs),
                g.Sum(x => x.RequestBytes),
                g.Sum(x => x.ResponseBytes),
                g.Sum(x => x.RecordsIn),
                g.Sum(x => x.RecordsOut),
                g.Sum(x => x.Duplicates),
                g.Sum(x => x.Merged),
                g.Sum(x => x.Flagged),
                g.Sum(x => x.Rejected)))
            .ToListAsync(ct);

        return new ExperimentStats(
            records,
            deleted,
            await _db.Conflicts.CountAsync(c => c.Status == ConflictStatus.Open, ct),
            await _db.Conflicts.CountAsync(c => c.Status == ConflictStatus.Resolved, ct),
            await _db.ProcessedOperations.CountAsync(ct),
            await _db.RecordHistory.CountAsync(ct),
            sync.OrderBy(s => s.Endpoint).ThenBy(s => s.Strategy).ThenBy(s => s.NetworkProfile).ToList());
    }

    public async Task<string> ExportSyncLogCsvAsync(DateTime? since, CancellationToken ct = default)
    {
        var query = _db.SyncLogs.AsNoTracking();
        if (since is not null) query = query.Where(l => l.At >= since.Value);
        var rows = await query.OrderBy(l => l.Id).ToListAsync(ct);

        var csv = new StringBuilder();
        csv.AppendLine("id,at,endpoint,strategy,network_profile,device_id,user_id,records_in,records_out," +
                       "applied,duplicates,merged,flagged,rejected,request_bytes,response_bytes,server_ms,status,success");

        foreach (var r in rows)
        {
            csv.AppendJoin(',',
                r.Id.ToString(CultureInfo.InvariantCulture),
                r.At.ToString("yyyy-MM-ddTHH:mm:ss.fffZ", CultureInfo.InvariantCulture),
                r.Endpoint,
                r.Strategy ?? string.Empty,
                r.NetworkProfile ?? string.Empty,
                Csv(r.DeviceId),
                r.UserId?.ToString() ?? string.Empty,
                r.RecordsIn.ToString(CultureInfo.InvariantCulture),
                r.RecordsOut.ToString(CultureInfo.InvariantCulture),
                r.Applied.ToString(CultureInfo.InvariantCulture),
                r.Duplicates.ToString(CultureInfo.InvariantCulture),
                r.Merged.ToString(CultureInfo.InvariantCulture),
                r.Flagged.ToString(CultureInfo.InvariantCulture),
                r.Rejected.ToString(CultureInfo.InvariantCulture),
                r.RequestBytes.ToString(CultureInfo.InvariantCulture),
                r.ResponseBytes.ToString(CultureInfo.InvariantCulture),
                r.DurationMs.ToString(CultureInfo.InvariantCulture),
                r.StatusCode.ToString(CultureInfo.InvariantCulture),
                r.Success ? "true" : "false");
            csv.Append('\n');
        }

        return csv.ToString();
    }

    /// <summary>Quotes a value if it contains a comma or quote (device ids are free text).</summary>
    private static string Csv(string? value)
    {
        if (string.IsNullOrEmpty(value)) return string.Empty;
        return value.Contains(',') || value.Contains('"') ? "\"" + value.Replace("\"", "\"\"") + "\"" : value;
    }
}
