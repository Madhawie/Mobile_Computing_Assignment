using System.Data;
using System.Text.Json;
using System.Text.Json.Nodes;
using LittleBloom.Application.Common;
using LittleBloom.Application.Sync;
using LittleBloom.Domain.Entities;
using LittleBloom.Domain.Enums;
using LittleBloom.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LittleBloom.Infrastructure.Sync;

/// <summary>
/// POST /api/sync/push (api.md section 4). For every change, in the order the phone sent them:
///   1. Already processed this operationId?  → "duplicate" (idempotency, experiment E4)
///   2. Known entity, valid op, valid values? → else "rejected" (only this change)
///   3. Parent exists and is in the user's area? → else "rejected"
///   4. Apply with the batch's strategy: S1/S2 overwrite (last upload wins),
///      S3 asks ConflictResolver (version check + field-level merge)
///   5. Save record + history row + processed operation (+ conflict) in ONE transaction
/// Step 5 is the key to "no loss, no duplicates": either all three rows are saved or none,
/// so a retried change is either found in ProcessedOperations or applied for the first time.
/// </summary>
public class PushService : IPushService
{
    private const string OpUpsert = "upsert";
    private const string OpDelete = "delete";

    /// <summary>How often one change is retried when another device wrote the same record at the same moment.</summary>
    private const int MaxAttempts = 3;

    private readonly AppDbContext _db;

    public PushService(AppDbContext db) => _db = db;

    public async Task<PushResponse> PushAsync(SyncUser user, PushRequest request, CancellationToken ct = default)
    {
        if (user.Role == UserRole.Mother)
            throw new AppException(403, ErrorCodes.Forbidden, "Mothers can view records but not change them.");

        var changes = request.Changes ?? [];
        if (changes.Count > SyncLimits.MaxPushChanges)
            throw new AppException(413, ErrorCodes.BatchTooLarge,
                $"At most {SyncLimits.MaxPushChanges} changes per push. Split the batch.");

        if (!Enum.TryParse<SyncStrategy>(request.Strategy, ignoreCase: true, out var strategy)
            || !Enum.IsDefined(strategy))
            throw new AppException(400, ErrorCodes.ValidationFailed, "strategy must be S1, S2 or S3.");

        var results = new List<ChangeResult>(changes.Count);
        long lastSeq = 0;

        foreach (var change in changes)
        {
            var (result, seq) = await ProcessChangeAsync(user, strategy, request.DeviceId, change, ct);
            results.Add(result);
            lastSeq = Math.Max(lastSeq, seq);
        }

        return new PushResponse(results, DateTime.UtcNow, lastSeq);
    }

    private async Task<(ChangeResult Result, long Seq)> ProcessChangeAsync(
        SyncUser user, SyncStrategy strategy, string deviceId, PushChange change, CancellationToken ct, int attempt = 1)
    {
        // 1. Idempotency: a retry of a change we already saved gets the first answer again.
        var done = await _db.ProcessedOperations.AsNoTracking()
            .FirstOrDefaultAsync(p => p.OperationId == change.OperationId, ct);
        if (done is not null) return (Duplicate(done), 0);

        // 2. Basic checks on this one change.
        var info = EntityRegistry.Find(change.Entity);
        if (info is null) return (Reject(change, ErrorCodes.UnknownEntity), 0);
        if (change.Op is not (OpUpsert or OpDelete)) return (Reject(change, ErrorCodes.InvalidField, "op"), 0);

        SyncEntity? incoming = null;
        if (change.Data is not null)
        {
            try
            {
                incoming = SyncJson.FromJson(change.Data, info.ClrType) as SyncEntity;
            }
            catch (JsonException ex)
            {
                return (Reject(change, ErrorCodes.InvalidField, FieldFromPath(ex.Path)), 0);
            }
        }

        if (incoming is null && change.Op == OpUpsert) return (Reject(change, ErrorCodes.InvalidField, "data"), 0);
        if (incoming is not null)
        {
            if (incoming.Id != change.RecordId) return (Reject(change, ErrorCodes.InvalidField, "id"), 0);
            if (change.Op == OpDelete) incoming.Deleted = true;
            var bad = RecordValidator.FirstInvalidField(incoming);
            if (bad is not null) return (Reject(change, ErrorCodes.InvalidField, bad), 0);
        }

        await using var tx = await _db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, ct);
        try
        {
            var existing = await _db.FindAsync(info.ClrType, [change.RecordId], ct) as SyncEntity;
            if (existing is null && incoming is null)
                return (Reject(change, ErrorCodes.InvalidField, "data"), 0); // delete of a record the server never had, without data

            // A delete may come without data: then it is the server copy marked as deleted by this phone.
            incoming ??= MarkedDeleted(info, existing!, deviceId);

            // 3. Which area does the record belong to, and may this user touch it?
            var (scopeArea, scopeError) = await FindScopeAreaAsync(info, incoming, ct);
            if (scopeError is not null) return (Reject(change, scopeError), 0);
            if (!user.CoversArea(scopeArea!) || (existing is not null && !user.CoversArea(existing.ScopeAreaId)))
                return (Reject(change, ErrorCodes.OutOfArea), 0);
            if (user.Role == UserRole.Supervisor && existing is null)
                return (Reject(change, ErrorCodes.Forbidden), 0); // supervisors edit at the clinic, PHMs create

            // 4. Apply.
            var outcome = strategy switch
            {
                SyncStrategy.S3 => await ApplyVersionedAsync(info, existing, incoming, change, ct),
                _ => Overwrite(existing, incoming), // S1 and S2
            };

            var record = outcome.Record;
            record.ScopeAreaId = record is Mother m ? m.AreaId : scopeArea!;
            record.ChangeSeq = await _db.NextChangeSeqAsync(ct);

            if (outcome.Conflict is not null)
            {
                outcome.Conflict.ScopeAreaId = record.ScopeAreaId;
                _db.Conflicts.Add(outcome.Conflict);
            }

            // 5. History + processed operation, saved together with the record.
            _db.RecordHistory.Add(new RecordHistory
            {
                Entity = info.Name,
                RecordId = record.Id,
                Version = record.Version,
                ChangedFields = outcome.ChangedFields,
                SnapshotJson = SyncJson.ToJson(record, info.ClrType).ToJsonString(),
                DeviceId = record.DeviceId,
                Strategy = strategy.ToString(),
                CreatedAt = DateTime.UtcNow,
            });

            var processed = new ProcessedOperation
            {
                OperationId = change.OperationId,
                Entity = info.Name,
                RecordId = record.Id,
                DeviceId = record.DeviceId,
                Status = outcome.Status,
                NewVersion = record.Version,
                ConflictId = outcome.Conflict?.Id,
                ProcessedAt = DateTime.UtcNow,
            };
            _db.ProcessedOperations.Add(processed);

            await _db.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);

            // After a merge the phone's copy is out of date, so send back the record as the server now has it.
            var returned = outcome.Status is ChangeStatus.ConflictMerged or ChangeStatus.ConflictFlagged
                ? SyncJson.ToJson(record, info.ClrType)
                : null;
            return (new ChangeResult(change.OperationId, outcome.Status, record.Id, record.Version,
                outcome.Conflict?.Id, returned), record.ChangeSeq);
        }
        catch (DbUpdateConcurrencyException) when (attempt < MaxAttempts)
        {
            // Another device saved this record between our read and our write (Version no longer matched).
            // Start this change again so it sees the newest version; S3 will then detect the conflict.
            await tx.RollbackAsync(ct);
            _db.ChangeTracker.Clear();
            return await ProcessChangeAsync(user, strategy, deviceId, change, ct, attempt + 1);
        }
        catch (DbUpdateException)
        {
            await tx.RollbackAsync(ct);
            _db.ChangeTracker.Clear();

            // Two copies of the same retry arrived at the same moment and the other one won. Not an error.
            var first = await _db.ProcessedOperations.AsNoTracking()
                .FirstOrDefaultAsync(p => p.OperationId == change.OperationId, ct);
            if (first is not null) return (Duplicate(first), 0);
            throw;
        }
        finally
        {
            _db.ChangeTracker.Clear(); // each change starts clean; keeps memory flat for big S1 batches
        }
    }

    /// <summary>
    /// S3: compare versions and fields with ConflictResolver (api.md section 6).
    /// Nothing is ever silently lost: a losing value goes into a Conflict row for a person to check,
    /// and the previous server value is still in RecordHistory.
    /// </summary>
    private async Task<ApplyOutcome> ApplyVersionedAsync(
        EntityInfo info, SyncEntity? existing, SyncEntity incoming, PushChange change, CancellationToken ct)
    {
        if (existing is null)
        {
            // First time the server sees this record: nothing to conflict with.
            incoming.Version = 1;
            _db.Add(incoming);
            return new ApplyOutcome(incoming, ChangeStatus.Applied, "*");
        }

        // Fields the server changed after the version the phone started from.
        var historyRows = await _db.RecordHistory.AsNoTracking()
            .Where(h => h.Entity == info.Name && h.RecordId == existing.Id && h.Version > change.BaseVersion)
            .Select(h => h.ChangedFields)
            .ToListAsync(ct);
        var serverChanged = historyRows
            .SelectMany(f => f.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            .ToHashSet(StringComparer.Ordinal);

        var serverVersion = existing.Version;
        var serverDeviceId = existing.DeviceId; // who made the server copy, before it is overwritten below
        var result = ConflictResolver.Resolve(new ResolveInput(
            Server: SyncJson.ToJson(existing, info.ClrType),
            ServerVersion: serverVersion,
            ServerChangedSinceBase: serverChanged,
            Incoming: SyncJson.ToJson(incoming, info.ClrType), // same JSON form as the server copy
            BaseVersion: change.BaseVersion,
            IncomingChangedFields: change.ChangedFields ?? [],
            IncomingIsDelete: change.Op == OpDelete));

        var merged = (SyncEntity)SyncJson.FromJson(result.Merged, info.ClrType)!;
        _db.Entry(existing).CurrentValues.SetValues(merged);
        existing.Version = serverVersion + 1;

        var status = result.Outcome switch
        {
            ResolveOutcome.Merged => ChangeStatus.ConflictMerged,
            ResolveOutcome.Flagged => ChangeStatus.ConflictFlagged,
            _ => ChangeStatus.Applied,
        };

        Conflict? conflict = null;
        if (result.Outcome == ResolveOutcome.Flagged)
        {
            var fields = new JsonArray();
            foreach (var c in result.Conflicts)
            {
                fields.Add(new JsonObject
                {
                    ["field"] = c.Field,
                    ["kept"] = c.Kept?.DeepClone(),
                    ["lost"] = c.Lost?.DeepClone(),
                    ["lostSide"] = c.LostSide,
                    ["lostDeviceId"] = c.LostSide == "phone" ? incoming.DeviceId : serverDeviceId,
                });
            }

            conflict = new Conflict
            {
                Id = Guid.NewGuid(),
                Entity = info.Name,
                RecordId = existing.Id,
                Kind = result.Kind ?? "sameField",
                FieldsJson = fields.ToJsonString(),
                CreatedAt = DateTime.UtcNow,
            };
        }

        return new ApplyOutcome(existing, status, string.Join(',', result.ChangedFields), conflict);
    }

    /// <summary>A copy of the server record, marked deleted by this phone (for a delete sent without data).</summary>
    private static SyncEntity MarkedDeleted(EntityInfo info, SyncEntity existing, string deviceId)
    {
        var copy = (SyncEntity)SyncJson.FromJson(SyncJson.ToJson(existing, info.ClrType), info.ClrType)!;
        copy.Deleted = true;
        copy.DeviceId = deviceId;
        copy.UpdatedAt = DateTime.UtcNow;
        return copy;
    }

    /// <summary>S1 and S2: the uploaded record replaces the server copy, whatever changed in between.</summary>
    private ApplyOutcome Overwrite(SyncEntity? existing, SyncEntity incoming)
    {
        var newVersion = (existing?.Version ?? 0) + 1;

        if (existing is null)
        {
            incoming.Version = newVersion;
            _db.Add(incoming);
            return new ApplyOutcome(incoming, ChangeStatus.Applied, "*");
        }

        // Copy every field from the upload onto the tracked row; server-only fields are set again by the caller.
        _db.Entry(existing).CurrentValues.SetValues(incoming);
        existing.Version = newVersion;
        return new ApplyOutcome(existing, ChangeStatus.Applied, "*");
    }

    /// <summary>
    /// The area of a mother is her own areaId; every other record takes the area of its parent.
    /// Returns PARENT_NOT_FOUND if the parent was never synced.
    /// </summary>
    private async Task<(string? Area, string? Error)> FindScopeAreaAsync(EntityInfo info, SyncEntity record, CancellationToken ct)
    {
        if (record is Mother mother) return (mother.AreaId, null);

        var parentId = info.ParentIdOf!(record);
        var parent = await _db.FindAsync(info.ParentType!, [parentId], ct) as SyncEntity;
        return parent is null ? (null, ErrorCodes.ParentNotFound) : (parent.ScopeAreaId, null);
    }

    private static ChangeResult Duplicate(ProcessedOperation p) =>
        new(p.OperationId, ChangeStatus.Duplicate, p.RecordId, p.NewVersion, p.ConflictId);

    private static ChangeResult Reject(PushChange c, string code, string? field = null) =>
        new(c.OperationId, ChangeStatus.Rejected, c.RecordId, Error: new ChangeError(code, field));

    /// <summary>"$.weightKg" → "weightKg".</summary>
    private static string? FieldFromPath(string? path) =>
        string.IsNullOrEmpty(path) ? null : path.TrimStart('$', '.');

    private sealed record ApplyOutcome(SyncEntity Record, string Status, string ChangedFields, Conflict? Conflict = null);
}
