using System.Data;
using System.Text.Json;
using LittleBloom.Application.Common;
using LittleBloom.Application.Sync;
using LittleBloom.Domain.Entities;
using LittleBloom.Domain.Enums;
using LittleBloom.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace LittleBloom.Infrastructure.Sync;

/// <summary>
/// POST /api/sync/push (api.md section 4). For every change, in the order the phone sent them:
///   1. Already processed this operationId?  → "duplicate" (idempotency, experiment E4)
///   2. Known entity, valid op, valid values? → else "rejected" (only this change)
///   3. Parent exists and is in the user's area? → else "rejected"
///   4. Apply with the batch's strategy: S1/S2 overwrite (last upload wins)
///   5. Save record + history row + processed operation in ONE transaction
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
            var (result, seq) = await ProcessChangeAsync(user, strategy, change, ct);
            results.Add(result);
            lastSeq = Math.Max(lastSeq, seq);
        }

        return new PushResponse(results, DateTime.UtcNow, lastSeq);
    }

    private async Task<(ChangeResult Result, long Seq)> ProcessChangeAsync(
        SyncUser user, SyncStrategy strategy, PushChange change, CancellationToken ct, int attempt = 1)
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

            // 3. Which area does the record belong to, and may this user touch it?
            var (scopeArea, scopeError) = await FindScopeAreaAsync(info, incoming ?? existing!, ct);
            if (scopeError is not null) return (Reject(change, scopeError), 0);
            if (!user.CoversArea(scopeArea!) || (existing is not null && !user.CoversArea(existing.ScopeAreaId)))
                return (Reject(change, ErrorCodes.OutOfArea), 0);
            if (user.Role == UserRole.Supervisor && existing is null)
                return (Reject(change, ErrorCodes.Forbidden), 0); // supervisors edit at the clinic, PHMs create

            // 4. Apply.
            var outcome = strategy switch
            {
                SyncStrategy.S1 or SyncStrategy.S2 => Overwrite(info, existing, incoming!),
                _ => throw new AppException(400, ErrorCodes.ValidationFailed, "S3 is not available yet."),
            };

            var record = outcome.Record;
            record.ScopeAreaId = scopeArea!;
            record.ChangeSeq = await NextChangeSeqAsync(ct);

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
                ProcessedAt = DateTime.UtcNow,
            };
            _db.ProcessedOperations.Add(processed);

            await _db.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);

            return (new ChangeResult(change.OperationId, outcome.Status, record.Id, record.Version), record.ChangeSeq);
        }
        catch (DbUpdateConcurrencyException) when (attempt < MaxAttempts)
        {
            // Another device saved this record between our read and our write (Version no longer matched).
            // Start this change again so it sees the newest version; S3 will then detect the conflict.
            await tx.RollbackAsync(ct);
            _db.ChangeTracker.Clear();
            return await ProcessChangeAsync(user, strategy, change, ct, attempt + 1);
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

    /// <summary>S1 and S2: the uploaded record replaces the server copy, whatever changed in between.</summary>
    private ApplyOutcome Overwrite(EntityInfo info, SyncEntity? existing, SyncEntity incoming)
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

    /// <summary>Takes the next number from the SQL Server sequence, inside the current transaction.</summary>
    private async Task<long> NextChangeSeqAsync(CancellationToken ct)
    {
        var connection = _db.Database.GetDbConnection();
        await using var command = connection.CreateCommand();
        command.CommandText = $"SELECT NEXT VALUE FOR dbo.{AppDbContext.ChangeSequence}";
        command.Transaction = _db.Database.CurrentTransaction?.GetDbTransaction();
        if (connection.State != ConnectionState.Open) await connection.OpenAsync(ct);
        return Convert.ToInt64(await command.ExecuteScalarAsync(ct));
    }

    private static ChangeResult Duplicate(ProcessedOperation p) =>
        new(p.OperationId, ChangeStatus.Duplicate, p.RecordId, p.NewVersion, p.ConflictId);

    private static ChangeResult Reject(PushChange c, string code, string? field = null) =>
        new(c.OperationId, ChangeStatus.Rejected, c.RecordId, Error: new ChangeError(code, field));

    /// <summary>"$.weightKg" → "weightKg".</summary>
    private static string? FieldFromPath(string? path) =>
        string.IsNullOrEmpty(path) ? null : path.TrimStart('$', '.');

    private sealed record ApplyOutcome(SyncEntity Record, string Status, string ChangedFields);
}
