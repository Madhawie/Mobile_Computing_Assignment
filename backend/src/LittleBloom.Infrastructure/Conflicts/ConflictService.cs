using System.Data;
using System.Text.Json.Nodes;
using LittleBloom.Application.Common;
using LittleBloom.Application.Conflicts;
using LittleBloom.Application.Sync;
using LittleBloom.Domain.Entities;
using LittleBloom.Domain.Enums;
using LittleBloom.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LittleBloom.Infrastructure.Conflicts;

/// <summary>
/// Conflict review (api.md section 7). S3 never silently drops an edit: when two devices change
/// the same field, the newest value is kept and the other is stored in a Conflict row.
/// Here a PHM or supervisor sees both values and decides:
///   keep "current"  → the record stays as it is; the conflict is closed.
///   keep "previous" → the lost values are written back as a NEW version (it syncs to every phone).
/// </summary>
public class ConflictService : IConflictService
{
    private const int MaxListed = 200;
    private const string ReviewDeviceId = "conflict-review";

    private readonly AppDbContext _db;

    public ConflictService(AppDbContext db) => _db = db;

    public async Task<List<ConflictDto>> ListAsync(SyncUser user, string? status, CancellationToken ct = default)
    {
        EnsureStaff(user);

        var query = InScope(_db.Conflicts.AsNoTracking(), user);
        query = (status ?? "open").ToLowerInvariant() switch
        {
            "open" => query.Where(c => c.Status == ConflictStatus.Open),
            "resolved" => query.Where(c => c.Status == ConflictStatus.Resolved),
            "all" => query,
            _ => throw new AppException(400, ErrorCodes.ValidationFailed, "status must be open, resolved or all."),
        };

        var rows = await query.OrderByDescending(c => c.CreatedAt).Take(MaxListed).ToListAsync(ct);
        return rows.Select(ToDto).ToList();
    }

    public async Task<ResolveConflictResponse> ResolveAsync(
        SyncUser user, Guid conflictId, ResolveConflictBody body, CancellationToken ct = default)
    {
        EnsureStaff(user);

        var keep = body.Keep?.ToLowerInvariant();
        if (keep is not (ConflictKeep.Current or ConflictKeep.Previous))
            throw new AppException(400, ErrorCodes.ValidationFailed, "keep must be \"current\" or \"previous\".");

        await using var tx = await _db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, ct);

        var conflict = await InScope(_db.Conflicts, user).FirstOrDefaultAsync(c => c.Id == conflictId, ct)
                       ?? throw new AppException(404, ErrorCodes.NotFound, "Conflict not found.");
        if (conflict.Status == ConflictStatus.Resolved)
            throw new AppException(409, ErrorCodes.AlreadyResolved, "This conflict was already resolved.");

        var info = EntityRegistry.Find(conflict.Entity)
                   ?? throw new AppException(500, ErrorCodes.ServerError, "Unknown entity in conflict.");
        var record = await _db.FindAsync(info.ClrType, [conflict.RecordId], ct) as SyncEntity
                     ?? throw new AppException(404, ErrorCodes.NotFound, "The record of this conflict no longer exists.");

        if (keep == ConflictKeep.Previous)
        {
            var fields = JsonNode.Parse(conflict.FieldsJson) as JsonArray ?? new JsonArray();
            var restored = ConflictReverter.WriteBackLostValues(SyncJson.ToJson(record, info.ClrType), fields);

            var version = record.Version;
            var scope = record.ScopeAreaId;
            _db.Entry(record).CurrentValues.SetValues((SyncEntity)SyncJson.FromJson(restored, info.ClrType)!);

            // A normal new version: other phones receive it on their next pull.
            record.Version = version + 1;
            record.ScopeAreaId = scope;
            record.UpdatedAt = DateTime.UtcNow;
            record.DeviceId = ReviewDeviceId;
            record.ChangeSeq = await _db.NextChangeSeqAsync(ct);

            _db.RecordHistory.Add(new RecordHistory
            {
                Entity = info.Name,
                RecordId = record.Id,
                Version = record.Version,
                ChangedFields = string.Join(',', ConflictReverter.FieldNames(fields)),
                SnapshotJson = SyncJson.ToJson(record, info.ClrType).ToJsonString(),
                DeviceId = ReviewDeviceId,
                Strategy = "S3",
                CreatedAt = DateTime.UtcNow,
            });
        }

        conflict.Status = ConflictStatus.Resolved;
        conflict.ResolvedAt = DateTime.UtcNow;
        conflict.ResolvedBy = user.UserId;
        conflict.Resolution = keep;

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        return new ResolveConflictResponse(conflict.Id, keep, record.Version, SyncJson.ToJson(record, info.ClrType));
    }

    private static void EnsureStaff(SyncUser user)
    {
        if (user.Role == UserRole.Mother)
            throw new AppException(403, ErrorCodes.Forbidden, "Only staff can review conflicts.");
    }

    /// <summary>Same scope as sync: PHM her area, MOH staff their division.</summary>
    private static IQueryable<Conflict> InScope(IQueryable<Conflict> query, SyncUser user)
    {
        if (user.Role == UserRole.Phm)
        {
            var area = user.AreaId ?? string.Empty;
            return query.Where(c => c.ScopeAreaId == area);
        }

        var prefix = user.MohId + "-";
        return query.Where(c => c.ScopeAreaId.StartsWith(prefix));
    }

    private static ConflictDto ToDto(Conflict c) => new(
        c.Id,
        c.Entity,
        c.RecordId,
        c.Kind,
        JsonNode.Parse(c.FieldsJson) as JsonArray ?? new JsonArray(),
        c.Status.ToString().ToLowerInvariant(),
        c.CreatedAt,
        c.ResolvedAt,
        c.Resolution);
}
