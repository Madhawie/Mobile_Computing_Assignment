using LittleBloom.Application.Common;
using LittleBloom.Application.Sync;
using LittleBloom.Domain.Entities;
using LittleBloom.Domain.Enums;
using LittleBloom.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LittleBloom.Infrastructure.Sync;

/// <summary>
/// GET /api/sync/pull (api.md section 5).
/// Returns rows with ChangeSeq &gt; since, oldest first, only inside the user's scope:
///   PHM               → her area
///   supervisor, admin → every area of the MOH division
///   mother            → her own record, her children, her visits, her children's growth and vaccines
/// Tombstones (deleted = true) are returned too, so a delete reaches every phone.
/// S1 calls with since = 0 (everything in scope); S2 and S3 send their stored cursor.
/// </summary>
public class PullService : IPullService
{
    private readonly AppDbContext _db;

    public PullService(AppDbContext db) => _db = db;

    public async Task<PullResponse> PullAsync(SyncUser user, long since, int limit, CancellationToken ct = default)
    {
        if (since < 0)
            throw new AppException(400, ErrorCodes.ValidationFailed, "since must be 0 or more.");
        limit = Math.Clamp(limit <= 0 ? PullLimits.DefaultLimit : limit, 1, PullLimits.MaxLimit);

        var take = limit + 1; // one extra row tells us whether another page is waiting
        var candidates = new List<PullCandidate>();

        if (user.Role == UserRole.Mother)
        {
            await AddMotherScopeAsync(user, since, take, candidates, ct);
        }
        else
        {
            await AddRowsAsync(InScope(_db.Mothers, user), since, take, candidates, ct);
            await AddRowsAsync(InScope(_db.MaternalVisits, user), since, take, candidates, ct);
            await AddRowsAsync(InScope(_db.Children, user), since, take, candidates, ct);
            await AddRowsAsync(InScope(_db.GrowthMeasurements, user), since, take, candidates, ct);
            await AddRowsAsync(InScope(_db.Vaccinations, user), since, take, candidates, ct);
        }

        return PullPager.Page(candidates, since, limit);
    }

    /// <summary>Staff scope: one area for a PHM, every "&lt;mohId&gt;-..." area for supervisor and admin.</summary>
    private static IQueryable<T> InScope<T>(IQueryable<T> table, SyncUser user) where T : SyncEntity
    {
        if (user.Role == UserRole.Phm)
        {
            var area = user.AreaId ?? string.Empty;
            return table.Where(r => r.ScopeAreaId == area);
        }

        var prefix = user.MohId + "-";
        return table.Where(r => r.ScopeAreaId.StartsWith(prefix));
    }

    /// <summary>A mother sees only her own family's records, read-only.</summary>
    private async Task AddMotherScopeAsync(SyncUser user, long since, int take, List<PullCandidate> into, CancellationToken ct)
    {
        if (user.MotherId is not Guid motherId) return;

        var childIds = await _db.Children.AsNoTracking()
            .Where(c => c.MotherId == motherId)
            .Select(c => c.Id)
            .ToListAsync(ct);

        await AddRowsAsync(_db.Mothers.Where(m => m.Id == motherId), since, take, into, ct);
        await AddRowsAsync(_db.MaternalVisits.Where(v => v.MotherId == motherId), since, take, into, ct);
        await AddRowsAsync(_db.Children.Where(c => c.MotherId == motherId), since, take, into, ct);
        await AddRowsAsync(_db.GrowthMeasurements.Where(g => childIds.Contains(g.ChildId)), since, take, into, ct);
        await AddRowsAsync(_db.Vaccinations.Where(v => childIds.Contains(v.ChildId)), since, take, into, ct);
    }

    private static async Task AddRowsAsync<T>(IQueryable<T> query, long since, int take,
        List<PullCandidate> into, CancellationToken ct) where T : SyncEntity
    {
        var rows = await query.AsNoTracking()
            .Where(r => r.ChangeSeq > since)
            .OrderBy(r => r.ChangeSeq)
            .Take(take)
            .ToListAsync(ct);

        var info = EntityRegistry.ForType(typeof(T));
        into.AddRange(rows.Select(r => new PullCandidate(info, r)));
    }
}
